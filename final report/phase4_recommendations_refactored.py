"""
PHASE 4: STOCKING RECOMMENDATIONS (descriptive, no scoring) - REFACTORED WITH BLUE THEME
===========================================================================================

1. New vs used split
2. Makes to stock - new cars
3. Makes / models to stock - used cars
4. Popular transfers right now (last 3 months)
5. Popular new registrations right now (last 3 months)

Charts now use the shared professional blue theme (viz_theme.py) to match
the ggplot2 visualizations elsewhere in the report.

Edit the CONFIG block if your file or column names differ.
"""

import pandas as pd
from pathlib import Path
import matplotlib
matplotlib.use('Agg')  # save to file, no pop-up window needed
import matplotlib.pyplot as plt

from viz_theme import BLUE, TREND_COLORS, apply_style, style_axes, save_fig as theme_save_fig

# ============================================================================
# CONFIG - check these match your data
# ============================================================================

TRANSFERS_PATH = '../outputs/CSVs/transfers_cleaned_records.csv'        # used cars
REGISTRATIONS_PATH = '../outputs/CSVs/registrations_cleaned_records.csv'  # new cars

DATE_COL = 'data_month_year'
MAKE_COL = 'make_standard'
MODEL_COL = 'model_standard'   # ASSUMED NAME - change me (set None if no model column)
VOLUME_COL = 'TOTAL'
AGE_COL = None                 # numeric vehicle-age column in transfers, e.g. 'vehicle_age'. None = skip age profile

TOP_N = 10
TOP_MODELS = 5
TREND_FLAT_BAND = 2.0          # YoY change within +/- this % is labelled "Flat"
OUT_DIR = Path('outputs/forecasts')
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Professional blue theme - matches visualization_theme.R palette
NEW_COLOR, USED_COLOR = BLUE['primary'], BLUE['secondary']


# ============================================================================
# HELPERS
# ============================================================================

def load(path):
    df = pd.read_csv(path)
    df[DATE_COL] = pd.to_datetime(df[DATE_COL])
    return df


def window(df, months, end):
    """Rows in the `months` months up to and including `end`."""
    start = end - pd.DateOffset(months=months)
    return df[(df[DATE_COL] > start) & (df[DATE_COL] <= end)]


def prev_window(df, months, end):
    """The `months` months immediately before the window above."""
    return window(df, months, end - pd.DateOffset(months=months))


def trend_label(pct):
    if pd.isna(pct):
        return 'n/a'
    if pct > TREND_FLAT_BAND:
        return 'Up'
    if pct < -TREND_FLAT_BAND:
        return 'Down'
    return 'Flat'


def ranked(df, end, keys, top_n=None):
    """Last-12m volume, previous-12m volume, YoY trend and share, grouped by `keys`."""
    cur_df = window(df, 12, end)
    cur = cur_df.groupby(keys)[VOLUME_COL].sum()
    prev = prev_window(df, 12, end).groupby(keys)[VOLUME_COL].sum()
    out = pd.DataFrame({'last_12m': cur}).join(prev.rename('prev_12m')).fillna({'prev_12m': 0})
    out['yoy_pct'] = ((out['last_12m'] - out['prev_12m']) / out['prev_12m'].where(out['prev_12m'] > 0) * 100).round(1)
    out['trend'] = out['yoy_pct'].apply(trend_label)
    out['share_pct'] = (out['last_12m'] / cur_df[VOLUME_COL].sum() * 100).round(2)
    out = out.sort_values('last_12m', ascending=False)
    if top_n:
        out = out.head(top_n)
    return out.reset_index()


def popular_now(df, end, keys, months=3):
    """Average monthly volume over the last `months` months, ranked."""
    w = window(df, months, end)
    out = (w.groupby(keys)[VOLUME_COL].sum() / months).rename('avg_monthly_volume').round(0).reset_index()
    out['share_pct'] = (out['avg_monthly_volume'] / out['avg_monthly_volume'].sum() * 100).round(2)
    out = out.sort_values('avg_monthly_volume', ascending=False).reset_index(drop=True)
    out.insert(0, 'rank', out.index + 1)
    return out


def names(df, col, n=3):
    return ', '.join(df[col].head(n).astype(str))


# ============================================================================
# LOAD
# ============================================================================

apply_style()

print('=' * 80)
print('PHASE 4: STOCKING RECOMMENDATIONS')
print('=' * 80)

transfers = load(TRANSFERS_PATH)
regs = load(REGISTRATIONS_PATH)

# Use a common end date so new and used are compared over the same period
end = min(transfers[DATE_COL].max(), regs[DATE_COL].max())
transfers = transfers[transfers[DATE_COL] <= end]
regs = regs[regs[DATE_COL] <= end]

print(f'Transfers (used): {len(transfers):,} rows | Registrations (new): {len(regs):,} rows')
print(f'Analysis end date: {end:%b %Y}')

# Make model key (make + model) if a model column exists
has_model = MODEL_COL is not None and MODEL_COL in transfers.columns
if has_model:
    transfers['make_model'] = transfers[MAKE_COL].astype(str) + ' ' + transfers[MODEL_COL].astype(str)
else:
    print('No model column found - model-level outputs will be skipped')


# ============================================================================
# 1. NEW vs USED SPLIT
# ============================================================================

print('\n' + '=' * 80)
print('1. NEW vs USED SPLIT')
print('=' * 80)

def split_row(label, used, new):
    total = used + new
    return {
        'period': label,
        'used_transfers': int(used),
        'new_registrations': int(new),
        'used_pct': round(used / total * 100, 1) if total else None,
        'new_pct': round(new / total * 100, 1) if total else None,
    }

rows = [
    split_row('Last 12 months', window(transfers, 12, end)[VOLUME_COL].sum(), window(regs, 12, end)[VOLUME_COL].sum()),
    split_row('Previous 12 months', prev_window(transfers, 12, end)[VOLUME_COL].sum(), prev_window(regs, 12, end)[VOLUME_COL].sum()),
    split_row('All time', transfers[VOLUME_COL].sum(), regs[VOLUME_COL].sum()),
]

# By calendar year
t_year = transfers.groupby(transfers[DATE_COL].dt.year)[VOLUME_COL].sum()
r_year = regs.groupby(regs[DATE_COL].dt.year)[VOLUME_COL].sum()
for yr in sorted(set(t_year.index) | set(r_year.index)):
    rows.append(split_row(f'CY{yr}', t_year.get(yr, 0), r_year.get(yr, 0)))

split_df = pd.DataFrame(rows)
print(split_df.to_string(index=False))

latest = split_df.iloc[0]
print(f"\n>> Recommend {latest['new_pct']:.0f}% new, {latest['used_pct']:.0f}% used (based on last 12 months)")

split_df.to_csv(OUT_DIR / 'phase4_new_vs_used_split.csv', index=False)


# ============================================================================
# 2. MAKES TO STOCK - NEW CARS
# ============================================================================

print('\n' + '=' * 80)
print('2. MAKES TO STOCK - NEW CARS (top by last-12-month registrations)')
print('=' * 80)

new_makes = ranked(regs, end, [MAKE_COL], TOP_N)
print(new_makes.to_string(index=False))
print(f'\n>> Stock {names(new_makes, MAKE_COL)} for new')

new_makes.to_csv(OUT_DIR / 'phase4_new_makes_to_stock.csv', index=False)


# ============================================================================
# 3. MAKES / MODELS TO STOCK - USED CARS
# ============================================================================

print('\n' + '=' * 80)
print('3. MAKES / MODELS TO STOCK - USED CARS (top by last-12-month transfers)')
print('=' * 80)

used_makes = ranked(transfers, end, [MAKE_COL], TOP_N)

if AGE_COL and AGE_COL in transfers.columns:
    w = window(transfers, 12, end)
    age = (w[AGE_COL] * w[VOLUME_COL]).groupby(w[MAKE_COL]).sum() / w.groupby(MAKE_COL)[VOLUME_COL].sum()
    used_makes['avg_age_yrs'] = used_makes[MAKE_COL].map(age).round(1)
else:
    print('(Age profile skipped - set AGE_COL in CONFIG to include it)')

print('\nTop makes:')
print(used_makes.to_string(index=False))
used_makes.to_csv(OUT_DIR / 'phase4_used_makes_to_stock.csv', index=False)

if has_model:
    used_models = ranked(transfers, end, ['make_model'], TOP_MODELS)
    if AGE_COL and AGE_COL in transfers.columns:
        w = window(transfers, 12, end)
        age_m = (w[AGE_COL] * w[VOLUME_COL]).groupby(w['make_model']).sum() / w.groupby('make_model')[VOLUME_COL].sum()
        used_models['avg_age_yrs'] = used_models['make_model'].map(age_m).round(1)
    print(f'\nTop {TOP_MODELS} models:')
    print(used_models.to_string(index=False))
    used_models.to_csv(OUT_DIR / 'phase4_used_models_to_stock.csv', index=False)
    print(f"\n>> Stock {names(used_models, 'make_model', TOP_MODELS)} for used")
else:
    print(f'\n>> Stock {names(used_makes, MAKE_COL)} for used')


# ============================================================================
# 4. POPULAR TRANSFERS RIGHT NOW (last 3 months, descriptive)
# ============================================================================

print('\n' + '=' * 80)
print('4. POPULAR TRANSFERS - LAST 3 MONTHS (avg per month)')
print('=' * 80)

if has_model:
    pop_transfers = popular_now(transfers, end, ['make_model'])
else:
    pop_transfers = popular_now(transfers, end, [MAKE_COL])
print(pop_transfers.head(TOP_N).to_string(index=False))

pop_transfers.to_csv(OUT_DIR / 'phase4_popular_transfers.csv', index=False)


# ============================================================================
# 5. POPULAR NEW REGISTRATIONS RIGHT NOW (last 3 months, descriptive)
# ============================================================================

print('\n' + '=' * 80)
print('5. POPULAR NEW REGISTRATIONS - LAST 3 MONTHS (avg per month)')
print('=' * 80)

pop_regs = popular_now(regs, end, [MAKE_COL])
print(pop_regs.head(TOP_N).to_string(index=False))

pop_regs.to_csv(OUT_DIR / 'phase4_popular_new_registrations.csv', index=False)


# ============================================================================
# CHARTS - PROFESSIONAL BLUE THEME
# ============================================================================

print('\n' + '=' * 80)
print('CHARTS')
print('=' * 80)

PLOT_DIR = OUT_DIR / 'charts'
PLOT_DIR.mkdir(parents=True, exist_ok=True)


def save_fig(fig, name):
    theme_save_fig(fig, PLOT_DIR / name)


def hbar(df, label_col, value_col, title, xlabel, filename, color_by_trend=False, annotate=None):
    """Horizontal bar chart, largest at top. annotate = column shown as text at bar end."""
    d = df.iloc[::-1]  # reverse so rank 1 is at the top
    colors = [TREND_COLORS[t] for t in d['trend']] if color_by_trend else NEW_COLOR
    fig, ax = plt.subplots(figsize=(9, max(3.5, 0.45 * len(d) + 1.5)))
    bars = ax.barh(d[label_col].astype(str), d[value_col], color=colors)
    ax.set_title(title, loc='left')
    ax.set_xlabel(xlabel)
    style_axes(ax, grid_axis='x', comma_format=False)
    ax.xaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:,.0f}'))
    if annotate:
        for bar, val in zip(bars, d[annotate]):
            ax.text(bar.get_width(), bar.get_y() + bar.get_height() / 2,
                    f'  {val}', va='center', fontsize=9, color=BLUE['text'])
        ax.margins(x=0.15)
    if color_by_trend:
        from matplotlib.patches import Patch
        ax.legend(handles=[Patch(color=TREND_COLORS[k], label=f'{k} YoY') for k in ['Up', 'Flat', 'Down']],
                  loc='lower right')
    save_fig(fig, filename)


# 1. New vs used split ------------------------------------------------------
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 5), gridspec_kw={'width_ratios': [1, 2]})

p = split_df[split_df['period'].isin(['Last 12 months', 'Previous 12 months'])]
x = range(len(p))
ax1.bar(x, p['used_pct'], color=USED_COLOR, label='Used (transfers)')
ax1.bar(x, p['new_pct'], bottom=p['used_pct'], color=NEW_COLOR, label='New (registrations)')
for i, (u, n) in enumerate(zip(p['used_pct'], p['new_pct'])):
    ax1.text(i, u / 2, f'{u:.0f}%', ha='center', va='center', color='white', fontweight='bold')
    ax1.text(i, u + n / 2, f'{n:.0f}%', ha='center', va='center', color='white', fontweight='bold')
ax1.set_xticks(list(x))
ax1.set_xticklabels(['Last 12m', 'Prev 12m'])
ax1.set_ylabel('Share of volume (%)')
ax1.set_title('Recent split', loc='left')

yr = split_df[split_df['period'].str.startswith('CY')]
xy = range(len(yr))
ax2.bar(xy, yr['used_pct'], color=USED_COLOR)
ax2.bar(xy, yr['new_pct'], bottom=yr['used_pct'], color=NEW_COLOR)
for i, (u, n) in enumerate(zip(yr['used_pct'], yr['new_pct'])):
    ax2.text(i, u / 2, f'{u:.0f}%', ha='center', va='center', color='white', fontsize=9)
    ax2.text(i, u + n / 2, f'{n:.0f}%', ha='center', va='center', color='white', fontsize=9)
ax2.set_xticks(list(xy))
ax2.set_xticklabels(yr['period'].str.replace('CY', ''))
ax2.set_title('By calendar year', loc='left')

for a in (ax1, ax2):
    a.set_ylim(0, 100)
    a.spines[['top', 'right']].set_visible(False)
    a.spines['left'].set_color(BLUE['border'])
    a.spines['bottom'].set_color(BLUE['border'])
ax1.legend(loc='upper center', bbox_to_anchor=(0.5, -0.08), ncol=1)
fig.suptitle('New vs Used Split', fontsize=14, fontweight='bold', color=BLUE['primary'], x=0.01, ha='left')
save_fig(fig, '01_new_vs_used_split.png')

# 2. New makes to stock -----------------------------------------------------
nm = new_makes.copy()
nm['label'] = nm.apply(lambda r: f"{r['share_pct']:.1f}% share | {r['yoy_pct']:+.1f}% YoY" if pd.notna(r['yoy_pct'])
                       else f"{r['share_pct']:.1f}% share", axis=1)
hbar(nm, MAKE_COL, 'last_12m', f'Makes to Stock - New (last 12 months to {end:%b %Y})',
     'New registrations', '02_new_makes_to_stock.png', color_by_trend=True, annotate='label')

# 3. Used makes and models to stock -----------------------------------------
um = used_makes.copy()
um['label'] = um.apply(lambda r: f"{r['share_pct']:.1f}% share | {r['yoy_pct']:+.1f}% YoY" if pd.notna(r['yoy_pct'])
                       else f"{r['share_pct']:.1f}% share", axis=1)
hbar(um, MAKE_COL, 'last_12m', f'Makes to Stock - Used (last 12 months to {end:%b %Y})',
     'Transfers', '03a_used_makes_to_stock.png', color_by_trend=True, annotate='label')

if has_model:
    umod = used_models.copy()
    umod['label'] = umod.apply(lambda r: f"{r['share_pct']:.1f}% share | {r['yoy_pct']:+.1f}% YoY" if pd.notna(r['yoy_pct'])
                               else f"{r['share_pct']:.1f}% share", axis=1)
    hbar(umod, 'make_model', 'last_12m', f'Top {TOP_MODELS} Used Models (last 12 months to {end:%b %Y})',
         'Transfers', '03b_used_models_to_stock.png', color_by_trend=True, annotate='label')

# 4. Popular transfers right now --------------------------------------------
pt = pop_transfers.head(TOP_N)
pt_label_col = 'make_model' if has_model else MAKE_COL
hbar(pt, pt_label_col, 'avg_monthly_volume', 'Popular Transfers Right Now (last 3 months)',
     'Average transfers per month', '04_popular_transfers.png')

# 5. Popular new registrations right now ------------------------------------
pr = pop_regs.head(TOP_N).copy()
pr['label'] = pr['share_pct'].map(lambda v: f'{v:.1f}%')
hbar(pr, MAKE_COL, 'avg_monthly_volume', 'Popular New Registrations Right Now (last 3 months)',
     'Average registrations per month', '05_popular_new_registrations.png', annotate='label')


# ============================================================================
# DONE
# ============================================================================

print('\n' + '=' * 80)
print('PHASE 4 COMPLETE')
print('=' * 80)
print(f'Outputs saved to {OUT_DIR}/')
