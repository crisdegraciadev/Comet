defmodule Comet.Repo.Migrations.DataEnumToTable do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO platforms (value, label, foreground, background, inserted_at, updated_at)
    SELECT DISTINCT platform, platform, '#FFFFFF', '#000000', now(), now()
    FROM games
    WHERE platform IS NOT NULL
    """)

    execute("""
    UPDATE games g
    SET platform_id = p.id
    FROM platforms p
    WHERE p.value = g.platform
    """)

    execute("""
    INSERT INTO statuses (value, label, foreground, background, inserted_at, updated_at)
    SELECT DISTINCT status, status, '#FFFFFF', '#000000', now(), now()
    FROM games
    WHERE status IS NOT NULL
    """)

    execute("""
    UPDATE games g
    SET status_id = s.id
    FROM statuses s
    WHERE s.value = g.status
    """)
  end

  def down do
    execute("DELETE FROM platforms")
    execute("DELETE FROM statuses")
  end
end
