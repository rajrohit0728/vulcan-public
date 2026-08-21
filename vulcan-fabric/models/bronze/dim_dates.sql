MODEL (
  name bronzev1.dim_dates,
  kind VIEW,
  owner 'shreyasikarwartmdcio',
  grains [dt],
  tags ('generated-data', 'bronze', 'date-dimension'),
  description 'Generated calendar data for date-based aggregations.',
  columns (
    dt DATE,
    year INTEGER,
    month INTEGER,
    day_of_week VARCHAR(255)
  ),
  column_descriptions (
    dt = 'Calendar date (primary date key)',
    year = 'Calendar year extracted from dt',
    month = 'Calendar month (1-12) extracted from dt',
    day_of_week = 'Day of week label (Monday through Sunday)'
  ),
  column_tags (
    dt = ('temporal', 'grain', 'date'),
    year = ('temporal', 'numeric'),
    month = ('temporal', 'numeric'),
    day_of_week = ('temporal', 'categorical')
  ),
  column_terms (
    dt = ('calendar.date', 'time.date_key'),
    year = ('calendar.year', 'time.year'),
    month = ('calendar.month', 'time.month'),
    day_of_week = ('calendar.day_of_week', 'time.weekday_label')
  ),
  assertions (
    unique_values(columns := (dt)),
    not_null(columns := (dt, year, month, day_of_week))
  )
);

SELECT
  dt,
  year,
  month,
  day_of_week
FROM public_shreya.dim_dates_ext;
