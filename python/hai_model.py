import numpy as np

# mu0 = mean log2 baseline titer, m1 = mean log2 day 22 titer (vaccine arm)
STRAINS = {
    "Strain A": {"mu0": 3.44, "m1": 7.42},
    "Strain B": {"mu0": 3.96, "m1": 7.64},
    "Strain C": {"mu0": 2.63, "m1": 5.61},
}
SD0, SD1, RHO = 1.5, 2.6, 0.45
AGE_SHIFT = 0.35
LLOQ = 10


def true_titers(rng, n, young, vacc, strains=STRAINS):
    # one subject effect shared across strains, so strains correlate
    z = rng.normal(size=n)
    shift = np.where(young, AGE_SHIFT, -AGE_SHIFT)
    out = {}
    for name, p in strains.items():
        t0 = p["mu0"] + shift + SD0 * (0.6 * z + 0.8 * rng.normal(size=n))
        fold = p["m1"] + RHO * (t0 - p["mu0"]) + SD1 * rng.normal(size=n)
        t1_vacc = np.maximum(fold, t0)
        t1_pbo = t0 + 0.3 * rng.normal(size=n)
        out[name] = (t0, np.where(vacc, t1_vacc, t1_pbo))
    return out


def to_grid(log2t):
    # reported titer = last twofold dilution (10, 20, ...); 0 means "<10"
    k = np.clip(np.floor(log2t - np.log2(LLOQ)), -1, 9)
    return np.where(k < 0, 0, LLOQ * 2 ** np.maximum(k, 0)).astype(int)


def gm(titer):
    return np.exp(np.log(np.where(titer == 0, LLOQ / 2, titer)).mean())


def seroconv(t0, t1):
    return np.where(t0 == 0, t1 >= 40, t1 >= 4 * t0)
