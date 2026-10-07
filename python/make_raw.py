"""Generate Rave-style raw EDC extracts for the synthetic study VAXF101."""
import csv
from datetime import date, timedelta
from pathlib import Path

import numpy as np
import pandas as pd

from hai_model import STRAINS, to_grid, true_titers

SEED = 20250301
OUT = Path(__file__).resolve().parents[1] / "data" / "raw"
N_RAND, N_FAIL = 240, 27
N_VACC = 160
# randomization list codes: A = VAXF-101, B = placebo

LOCAL_SEV = ["PAIN", "TENDERNESS"]
LOCAL_MM = ["REDNESS_MM", "SWELLING_MM", "INDURATION_MM"]
SYSTEMIC = ["CHILLS", "MALAISE", "MYALGIA", "HEADACHE", "ARTHRALGIA", "NAUSEA", "VOMITING"]
SOLICITED = LOCAL_SEV + LOCAL_MM + SYSTEMIC + ["FEVER"]

# % of subjects by maximum grade (1, 2, 3): vaccine, placebo
RATES = {
    "PAIN": ([54.7, 7.4, 0.1], [16.9, 0.7, 0.0]),
    "TENDERNESS": ([59.6, 7.3, 0.1], [20.3, 1.4, 0.0]),
    "REDNESS_MM": ([2.4, 0.1, 0.0], [0.7, 0.0, 0.0]),
    "SWELLING_MM": ([2.7, 0.8, 0.0], [0.7, 0.0, 0.0]),
    "INDURATION_MM": ([3.1, 0.1, 0.0], [0.0, 0.0, 0.0]),
    "CHILLS": ([4.9, 1.2, 0.0], [6.8, 1.4, 0.7]),
    "MALAISE": ([15.0, 3.9, 0.3], [12.2, 5.4, 0.7]),
    "MYALGIA": ([15.4, 3.1, 0.0], [9.5, 0.7, 0.7]),
    "HEADACHE": ([12.6, 3.6, 0.1], [15.5, 2.7, 1.4]),
    "ARTHRALGIA": ([5.7, 2.2, 0.0], [7.4, 0.0, 0.7]),
    "NAUSEA": ([1.9, 0.3, 0.1], [2.7, 0.0, 0.7]),
    "VOMITING": ([0.4, 0.3, 0.1], [0.0, 0.0, 0.0]),
    "FEVER": ([0.7, 0.7, 0.1], [0.7, 0.7, 0.0]),
}
# rare symptoms: keep at least this many vaccine subjects so grade derivations have data
MIN_VACC = {"REDNESS_MM": 3, "SWELLING_MM": 3, "INDURATION_MM": 3, "FEVER": 3}
SEV_TEXT = {0: "None", 1: "Mild", 2: "Moderate", 3: "Severe"}
MM_RANGE = {1: (25, 50), 2: (51, 100), 3: (101, 140)}
TEMP_RANGE = {1: (38.0, 38.4), 2: (38.5, 38.9), 3: (39.0, 39.6)}

AE_TERMS = {
    "Nasopharyngitis": ["runny nose", "Nasal congestion", "common cold", "cold"],
    "Cough": ["cough", "Cough "],
    "Oropharyngeal pain": ["sore throat", "Throat pain"],
    "Upper respiratory tract infection": ["URTI", "upper respiratory infection"],
    "Diarrhoea": ["diarrhea", "loose stools"],
    "Dizziness": ["dizzy", "Dizziness"],
    "Back pain": ["back pain", "lower back pain"],
    "Rash": ["rash on arm", "skin rash"],
    "Insomnia": ["insomnia", "trouble sleeping"],
    "Abdominal pain": ["stomach ache", "abdominal pain"],
    "Toothache": ["tooth ache", "toothache"],
}
SAE_TERMS = ["appendicitis", "fall with fracture of left wrist"]

RACES = ["White", "Asian", "Black or African American", "Other"]
FAIL_REASONS = [
    "Acute illness within 2 weeks of enrollment",
    "Received another vaccine within 30 days",
    "Unable to attend all scheduled visits",
    "Positive pregnancy test",
    "Medical condition not stable",
]


def d(x):
    return x.strftime("%d-%b-%Y").upper()


def partial(x, rng, p):
    # day unknown in a small share of dates
    return f"UN-{x.strftime('%b').upper()}-{x.year}" if rng.random() < p else d(x)


def temp_out(c, unit):
    return round(c * 9 / 5 + 32, 1) if unit == "F" else round(c, 1)


def make_subjects(rng):
    n = N_RAND + N_FAIL
    s = pd.DataFrame({"scrn": sorted(date(2025, 3, 3) + timedelta(days=int(x)) for x in rng.integers(0, 85, n))})
    s["site"] = rng.choice(["101", "102"], n)
    s["subject"] = s["site"] + "-" + (s.groupby("site").cumcount() + 1).astype(str).str.zfill(3)
    s["fail"] = False
    s.loc[rng.choice(n, N_FAIL, replace=False), "fail"] = True
    s["age"] = np.where(rng.random(n) < 0.55, rng.integers(18, 46, n), rng.integers(46, 61, n))
    s["stratum"] = np.where(s["age"] <= 45, "18-45", "46-60")
    # birth date from age at screening, always inside the same age year
    s["birth"] = [
        (pd.Timestamp(r.scrn) - pd.DateOffset(years=int(r.age)) - pd.Timedelta(days=int(rng.integers(0, 361)))).date()
        for r in s.itertuples()
    ]
    s["sex"] = rng.choice(["Male", "Female"], n)
    s["race"] = rng.choice(RACES, n, p=[0.35, 0.40, 0.15, 0.10])
    s["ethnic"] = rng.choice(["Hispanic or Latino", "Not Hispanic or Latino"], n, p=[0.18, 0.82])
    s["temp_unit"] = rng.choice(["C", "F"], n, p=[0.97, 0.03])
    return s


def randomize(s, rng):
    r = s[~s["fail"]].copy()
    r["trt"] = ""
    left = N_VACC
    strata = list(r["stratum"].unique())
    for i, st in enumerate(strata):
        idx = r.index[r["stratum"] == st]
        nv = left if i == len(strata) - 1 else round(len(idx) * 2 / 3)
        left -= nv
        codes = np.array(["A"] * nv + ["B"] * (len(idx) - nv))
        r.loc[idx, "trt"] = rng.permutation(codes)
    r["day1"] = [x + timedelta(days=int(rng.integers(1, 15))) for x in r["scrn"]]
    r["randnum"] = ["R" + str(i + 1).zfill(4) for i in range(len(r))]
    r["vacc"] = r["trt"] == "A"
    # not dosed: one per arm. dropout_day: study day of discontinuation (0 = completer)
    r["dosed"] = True
    r["dropout_day"] = 0
    pick = lambda mask, k: rng.choice(r.index[mask], k, replace=False)
    r.loc[pick(r["vacc"], 1), "dosed"] = False
    r.loc[pick(~r["vacc"], 1), "dosed"] = False
    dosed = r["dosed"]
    early = pick(dosed, 4)
    r.loc[early, "dropout_day"] = rng.integers(9, 21, 4)
    late = pick(dosed & (r["dropout_day"] == 0), 2)
    r.loc[late, "dropout_day"] = rng.integers(30, 81, 2)
    return r


def reaction_grades(rng, vacc):
    # max grade per subject and symptom, 0 = none
    n = len(vacc)
    g = {}
    for sym, (pv, pp) in RATES.items():
        cut = np.where(vacc[:, None], np.cumsum(pv), np.cumsum(pp)) / 100
        u = rng.random(n)[:, None]
        left = (cut > u).sum(axis=1)
        g[sym] = np.where(left == 0, 0, 4 - left)
        need = MIN_VACC.get(sym, 0) - (g[sym][vacc] > 0).sum()
        if need > 0:
            free = np.flatnonzero(vacc & (g[sym] == 0))
            pick = rng.choice(free, need, replace=False)
            g[sym][pick] = rng.choice([1, 2, 1], need)
    return g


def daily_profile(rng, peak):
    # grade by diary day 1..7 for one symptom
    if peak == 0:
        return [0] * 7
    onset = int(rng.choice([1, 2, 3, 4], p=[0.5, 0.3, 0.1, 0.1]))
    dur = int(rng.integers(1, 4))
    days = list(range(onset, min(onset + dur, 8)))
    prof = [0] * 7
    top = int(rng.choice(days))
    for k in days:
        prof[k - 1] = peak if k == top else int(rng.integers(1, peak + 1))
    return prof


def diary_value(rng, sym, grade, peak_day):
    if sym in LOCAL_SEV or sym in SYSTEMIC:
        return SEV_TEXT[grade]
    if sym in LOCAL_MM:
        if grade == 0:
            return 0
        if grade == 1 and not peak_day and rng.random() < 0.3:
            return int(rng.integers(12, 25))
        lo, hi = MM_RANGE[grade]
        return int(rng.integers(lo, hi + 1))
    return None


def make_diary(r, rng):
    g = reaction_grades(rng, r["vacc"].to_numpy())
    rows, obs = [], []
    for i, p in enumerate(r.itertuples()):
        if not p.dosed:
            continue
        prof = {s: daily_profile(rng, int(g[s][i])) for s in SOLICITED}
        for day in range(1, 8):
            if rng.random() < 0.04:
                continue
            row = {"SUBJECT": p.subject, "DIARYDAY": day, "DIARYDAT": d(p.day1 + timedelta(days=day - 1))}
            for s in LOCAL_SEV + LOCAL_MM + SYSTEMIC:
                peak = prof[s][day - 1] == g[s][i] and g[s][i] > 0
                row[s] = diary_value(rng, s, prof[s][day - 1], peak)
            fg = prof["FEVER"][day - 1]
            if fg:
                lo, hi = TEMP_RANGE[fg]
                c = rng.uniform(lo, hi)
            else:
                c = float(np.clip(rng.normal(36.7, 0.25), 36.0, 37.4))
            row["TEMP"] = temp_out(c, p.temp_unit)
            row["TEMPU"] = p.temp_unit
            rows.append(row)
        # 30-minute observation: pain/tenderness only, mild
        o = {"SUBJECT": p.subject, "OBSDAT": d(p.day1)}
        for s in LOCAL_SEV + LOCAL_MM + SYSTEMIC:
            o[s] = "None" if s not in LOCAL_MM else 0
        pa, te = (0.032, 0.019) if p.vacc else (0.0, 0.007)
        if rng.random() < pa:
            o["PAIN"] = "Mild"
        if rng.random() < te:
            o["TENDERNESS"] = "Mild"
        obs.append(o)
    cols = ["SUBJECT", "DIARYDAY", "DIARYDAT", "TEMP", "TEMPU"] + LOCAL_SEV + LOCAL_MM + SYSTEMIC
    return pd.DataFrame(rows)[cols], pd.DataFrame(obs)


def make_visits(r, rng):
    rows = []
    for p in r.itertuples():
        rows.append((p.subject, "Screening", p.scrn))
        rows.append((p.subject, "Day 1", p.day1))
        if not p.dosed:
            continue
        if p.dropout_day == 0 or p.dropout_day > 8:
            rows.append((p.subject, "Day 8", p.day1 + timedelta(days=7 + int(rng.integers(0, 3)))))
        if p.dropout_day == 0 or p.dropout_day > 24:
            off = int(rng.integers(-3, 4)) if rng.random() > 0.03 else int(rng.choice([-6, 6, 7]))
            rows.append((p.subject, "Day 22", p.day1 + timedelta(days=21 + off)))
        if p.dropout_day == 0:
            rows.append((p.subject, "Day 91", p.day1 + timedelta(days=90 + int(rng.integers(-7, 8)))))
    v = pd.DataFrame(rows, columns=["SUBJECT", "VISIT", "VISDAT"])
    return v


def make_hai(r, v, rng):
    d22 = v[v["VISIT"] == "Day 22"].set_index("SUBJECT")["VISDAT"]
    x = r
    young = (x["stratum"] == "18-45").to_numpy()
    t = true_titers(rng, len(x), young, x["vacc"].to_numpy())
    rows = []
    for k, p in enumerate(x.itertuples()):
        for visit, col, when in (("Day 1", 0, p.day1), ("Day 22", 1, d22.get(p.subject))):
            if when is None or (col == 0 and not p.dosed and rng.random() < 0.5):
                continue
            for name in STRAINS:
                val = int(to_grid(np.array([t[name][col][k]]))[0])
                res = "<10" if val == 0 else str(val)
                note = ""
                if rng.random() < 0.01:
                    res, note = "", "Insufficient sample"
                rows.append(
                    {
                        "SUBJECT": p.subject,
                        "VISIT": visit,
                        "COLLDAT": when.isoformat(),
                        "ANALYTE": f"HAI {name}",
                        "RESULT": res,
                        "UNIT": "titer",
                        "COMMENT": note,
                    }
                )
    return pd.DataFrame(rows)


def make_ae(r, rng):
    rows = []
    comp = r[r["dosed"] & (r["dropout_day"] == 0)]
    sae_idx = [rng.choice(comp.index[comp["vacc"]]), rng.choice(comp.index[~comp["vacc"]])]
    names, probs = list(AE_TERMS), np.ones(len(AE_TERMS)) / len(AE_TERMS)
    dosed = r[r["dosed"]]
    # exact share of subjects with an unsolicited AE per arm
    has_ae = set()
    for vacc, rate in ((True, 0.149), (False, 0.115)):
        idx = dosed.index[dosed["vacc"] == vacc]
        has_ae |= set(rng.choice(idx, round(rate * len(idx)), replace=False))
    for i, p in dosed.iterrows():
        last = p.dropout_day if p.dropout_day else 91
        n_ae = 1 + min(int(rng.poisson(0.3)), 2) if i in has_ae else 0
        for _ in range(n_ae):
            start = int(rng.integers(1, min(22, last) + 1))
            rows.append(ae_row(rng, p, start, str(rng.choice(AE_TERMS[str(rng.choice(names, p=probs))])), False))
        if i in sae_idx:
            n = sae_idx.index(i)
            rows.append(ae_row(rng, p, int(rng.integers(30, 86)), SAE_TERMS[n], True))
    return pd.DataFrame(rows)


def ae_row(rng, p, start, term, serious):
    dur = int(rng.integers(2, 12)) if not serious else int(rng.integers(5, 15))
    ongoing = (not serious) and rng.random() < 0.05
    s = p.day1 + timedelta(days=start - 1)
    e = s + timedelta(days=dur)
    sev = "Severe" if serious else str(rng.choice(["Mild", "Moderate", "Severe"], p=[0.80, 0.18, 0.02]))
    if serious:
        rel = "Not related"
    elif p.vacc:
        rel = str(rng.choice(["Not related", "Unlikely related", "Possibly related"], p=[0.7, 0.27, 0.03]))
    else:
        rel = str(rng.choice(["Not related", "Unlikely related"], p=[0.75, 0.25]))
    return {
        "SUBJECT": p.subject,
        "AETERM": term,
        "AESTDAT": partial(s, rng, 0.06),
        "AEENDAT": "" if ongoing else partial(e, rng, 0.03),
        "AEONGO": "Y" if ongoing else "N",
        "AESEV": sev,
        "AESER": "Y" if serious else "N",
        "AESHOSP": "Y" if serious else "N",
        "AEREL": rel,
        "AEACN": "None",
        "AEOUT": "Recovering" if ongoing else "Recovered/Resolved",
    }


def make_ds(s, r, v, rng):
    rows = []
    last = v.groupby("SUBJECT")["VISDAT"].max()
    for p in s.itertuples():
        if p.fail:
            rows.append((p.subject, d(p.scrn), "Screen Failure", ""))
    for p in r.itertuples():
        if not p.dosed:
            rows.append((p.subject, d(p.day1), "Withdrawal by Subject", "Withdrew before vaccination"))
        elif p.dropout_day:
            term = str(rng.choice(["Lost to Follow-up", "Withdrawal by Subject"]))
            # discontinuation is not dated before the last visit attended
            stop = max(p.day1 + timedelta(days=int(p.dropout_day) - 1), last[p.subject])
            rows.append((p.subject, d(stop), term, ""))
        else:
            rows.append((p.subject, d(last[p.subject]), "Completed", ""))
    return pd.DataFrame(rows, columns=["SUBJECT", "DSDAT", "DSTERM", "DSCOMMENT"])


def make_vitals(s, r, rng):
    day1 = r.set_index("subject")["day1"]
    rows = []
    for p in s.itertuples():
        visits = [("Screening", p.scrn)]
        if not p.fail:
            visits.append(("Day 1", day1[p.subject]))
        for visit, when in visits:
            c = float(np.clip(rng.normal(36.6, 0.2), 36.0, 37.3))
            rows.append(
                {
                    "SUBJECT": p.subject,
                    "VISIT": visit,
                    "VSDAT": d(when),
                    "SYSBP": int(rng.normal(120, 11)),
                    "DIABP": int(rng.normal(76, 8)),
                    "PULSE": int(rng.normal(72, 9)),
                    "TEMP": temp_out(c, p.temp_unit),
                    "TEMPU": p.temp_unit,
                }
            )
    return pd.DataFrame(rows)


def make_ex(r, rng):
    rows = []
    for p in r.itertuples():
        row = {"SUBJECT": p.subject, "EXDAT": d(p.day1), "EXTIM": "", "EXDOSE": "", "EXDOSEU": "", "EXROUTE": "", "EXLOC": "", "EXSIDE": "", "LOTNUM": "", "DOSED": "N", "NODOSERSN": "Subject withdrew consent"}
        if p.dosed:
            row.update(
                EXTIM=f"{int(rng.integers(8, 16)):02d}:{int(rng.integers(0, 60)):02d}",
                EXDOSE=0.5,
                EXDOSEU="mL",
                EXROUTE="Intramuscular",
                EXLOC="Deltoid",
                EXSIDE=str(rng.choice(["Left", "Right"], p=[0.8, 0.2])),
                LOTNUM=str(rng.choice(["L25A01", "L25A02"])),
                DOSED="Y",
                NODOSERSN="",
            )
        rows.append(row)
    return pd.DataFrame(rows)


def write(df, name):
    df.to_csv(OUT / f"{name}.csv", index=False, quoting=csv.QUOTE_ALL)
    print(f"{name:8s}{len(df):6d} rows")


def main():
    rng = np.random.default_rng(SEED)
    OUT.mkdir(parents=True, exist_ok=True)
    s = make_subjects(rng)
    r = randomize(s, rng)
    v = make_visits(r, rng)
    diary, obs = make_diary(r, rng)

    write(pd.DataFrame({"SUBJECT": s["subject"], "ICDAT": s["scrn"].map(d)}), "IC")
    write(
        pd.DataFrame(
            {"SUBJECT": s["subject"], "SITE": s["site"], "BRTHDAT": s["birth"].map(d), "SEX": s["sex"], "RACE": s["race"], "ETHNIC": s["ethnic"]}
        ),
        "DM",
    )
    ie = pd.DataFrame({"SUBJECT": s["subject"], "IEDAT": s["scrn"].map(d), "ELIGIBLE": np.where(s["fail"], "N", "Y")})
    ie["IETERM"] = [str(rng.choice(FAIL_REASONS)) if f else "" for f in s["fail"]]
    write(ie, "IE")
    write(
        pd.DataFrame(
            {"SUBJECT": r["subject"], "RANDNUM": r["randnum"], "RANDDAT": r["day1"].map(d), "STRATUM": r["stratum"], "TRTCODE": r["trt"]}
        ),
        "RAND",
    )
    fail = s[s["fail"]]
    scr = pd.DataFrame({"SUBJECT": fail["subject"], "VISIT": "Screening", "VISDAT": fail["scrn"]})
    v_all = pd.concat([v, scr], ignore_index=True)
    write(v_all.assign(VISDAT=v_all["VISDAT"].map(d)), "VISIT")
    write(make_vitals(s, r, rng), "VITALS")
    write(make_ex(r, rng), "EX")
    write(obs, "OBS30")
    write(diary, "DIARY")
    write(make_ae(r, rng), "AE")
    write(make_ds(s, r, v, rng), "DS")
    write(make_hai(r, v, rng), "LB_HAI")


if __name__ == "__main__":
    main()
