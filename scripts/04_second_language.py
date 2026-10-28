"""04_second_language.py -- Question 5: recompute the Question 3 band table and figure in Python.
Run from the repository root:  python scripts/04_second_language.py
Needs: pandas, numpy, matplotlib.
"""
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter

PROV, URBAN = 3, 2          # variant 3 = Sindh urban (35 = 4*8 + 3)

# --- load, merge, filter (same rules as the R scripts) ------------------------
person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv")
df = person.merge(hh[["hhid", "hhweight", "prov_code", "urban_rural"]], on="hhid", how="left")
e = df[(df.prov_code == PROV) & (df.urban_rural == URBAN) &
       (df.age >= 15) & (df.age <= 64) & (df.earn_annual > 0)].copy()

# --- band table ---------------------------------------------------------------
# floor(age/5)*5 gives right-open bands [15,20), [20,25), ... exactly like the R code.
# (R's cut() would default to right-closed bands, so I did not use it there.)
e["band_start"] = (e.age // 5 * 5).astype(int)
rows = []
for b, d in e.groupby("band_start"):
    mean = (d.earn_annual * d.hhweight).sum() / d.hhweight.sum()     # sum(w*x)/sum(w)
    rows.append({"band": f"{b}-{b + 4}", "midpoint": b + 2, "n": len(d), "mean_earn": round(mean)})
bands = pd.DataFrame(rows)
bands["thin"] = bands.n < 30
print(bands[["band", "n", "mean_earn"]].to_string(index=False))

# --- compare with R to the rupee ---------------------------------------------
r_path = "results/band_table_R.csv"
if os.path.exists(r_path):
    r = pd.read_csv(r_path)
    merged = r.merge(bands, on="band", suffixes=("_R", "_py"))
    assert len(merged) == len(bands) == len(r), "band lists differ"
    assert (merged.mean_earn_R == merged.mean_earn_py).all() and (merged.n_R == merged.n_py).all(), "tables differ!"
    row = merged[merged.band == "25-29"].iloc[0]
    print(f"\n25-29 band mean: R = {int(row.mean_earn_R):,}  Python = {int(row.mean_earn_py):,}  -> tables agree to the rupee")
else:
    print("Run scripts/03_relationship.R first to create results/band_table_R.csv for the comparison.")

# --- figure (settings chosen to match the ggplot version) ----------------------
# Defaults that differ in matplotlib: points are opaque, all four spines are drawn,
# the log axis shows 10^k tick labels and the y-range is automatic. I set alpha = 0.22,
# hid top/right spines, wrote tick labels in rupees and fixed ylim to Rs 10,000 - 10,000,000.
rng = np.random.default_rng(346)
jit = e.age + rng.uniform(-0.4, 0.4, len(e))
top = bands.loc[bands.mean_earn.idxmax()]

fig, ax = plt.subplots(figsize=(8, 5))
ax.scatter(jit, e.earn_annual, s=8, color="#595959", alpha=0.22, linewidths=0)
ax.plot(bands.midpoint, bands.mean_earn, color="#D9480F", lw=2)
ax.scatter(bands.midpoint, bands.mean_earn, s=70, zorder=3, edgecolor="#D9480F", linewidths=1.5,
           facecolor=np.where(bands.thin, "white", "#D9480F"))          # thin bands = hollow
ax.annotate(f"Highest mean: {top.band}\nRs {int(top.mean_earn):,}", (top.midpoint, top.mean_earn),
            xytext=(top.midpoint - 17, 2.4e6), color="#D9480F", fontweight="bold", fontsize=10,
            arrowprops=dict(arrowstyle="->", color="#D9480F"))
ax.set_yscale("log"); ax.set_ylim(1e4, 1e7); ax.set_xlim(14, 65)
ax.set_yticks([1e4, 1e5, 1e6, 1e7])
ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"Rs {int(v):,}"))
ax.yaxis.set_minor_formatter(FuncFormatter(lambda v, _: ""))
ax.set_xlabel("Age (years)"); ax.set_ylabel("Annual earnings (log scale)")
for sp in ["top", "right"]:
    ax.spines[sp].set_visible(False)
ax.set_title(f"Earnings rise with age in urban Sindh, peaking at ages {top.band}", loc="left", fontweight="bold")
fig.text(0.01, 0.01,
         f"Source: PSLM 2019-20. Sample: earners aged 15-64 in urban Sindh (n = {len(e)}).\n"
         "Weighting: hhweight; large markers are weighted mean earnings by 5-year age band.\n"
         "Hollow markers: bands with fewer than 30 unweighted observations. Points jittered horizontally (max 0.4 years).",
         fontsize=7.5, color="#595959", va="bottom")
fig.tight_layout(rect=(0, 0.09, 1, 1))
os.makedirs("figures", exist_ok=True)
plt.savefig("figures/relationship_python.svg")
print("Saved figures/relationship_python.svg")
