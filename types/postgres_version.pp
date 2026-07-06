# String representing a Postgresql major or major.minor version (e.g.
# '14', '15.1').
type Ovox::Postgres_version = Pattern[/^\d+(\.\d+)?$/]
