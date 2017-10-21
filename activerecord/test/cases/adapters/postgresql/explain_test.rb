# frozen_string_literal: true

require "cases/helper"
require "models/developer"
require "models/computer"

class PostgreSQLExplainTest < ActiveRecord::PostgreSQLTestCase
  fixtures :developers

  def test_explain_for_one_query
    explain = Developer.where(id: 1).explain
    assert_match %r(EXPLAIN for: SELECT "developers"\.\* FROM "developers" WHERE "developers"\."id" = (?:\$1 \[\["id", 1\]\]|1)), explain
    assert_match %(QUERY PLAN), explain
  end

  def test_explain_with_eager_loading
    explain = Developer.where(id: 1).includes(:audit_logs).explain
    assert_match %(QUERY PLAN), explain
    assert_match %r(EXPLAIN for: SELECT "developers"\.\* FROM "developers" WHERE "developers"\."id" = (?:\$1 \[\["id", 1\]\]|1)), explain
    assert_match %r(EXPLAIN for: SELECT "audit_logs"\.\* FROM "audit_logs" WHERE "audit_logs"\."developer_id" = (?:\$1 \[\["developer_id", 1\]\]|1)), explain
  end
end
