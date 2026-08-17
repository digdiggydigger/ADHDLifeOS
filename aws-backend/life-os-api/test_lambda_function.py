"""
Regression coverage for lambda_function.py's JSON serialization of DynamoDB
Decimal values. No boto3/AWS dependency — exercises _json_default/_response
directly as pure functions, since this file has no existing test harness.
Run: python3 -m unittest aws-backend/life-os-api/test_lambda_function.py -v
"""

import json
import sys
import unittest
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from lambda_function import (  # noqa: E402
    _json_default,
    _response,
    find_name_conflict,
    next_sort_order,
    plan_life_area_patch,
    plan_tag_cascade,
    plan_tag_merge,
    tally_tag_usage,
    validate_reorder,
)


def _tasktag(user_id, task_id, tag_id):
    return {
        "PK": f"USER#{user_id}",
        "SK": f"TASKTAG#{task_id}#{tag_id}",
        "entity": "TASKTAG",
        "taskId": task_id,
        "tagId": tag_id,
    }


def _capturetag(user_id, capture_id, tag_id):
    return {
        "PK": f"USER#{user_id}",
        "SK": f"CAPTURETAG#{capture_id}#{tag_id}",
        "entity": "CAPTURETAG",
        "captureId": capture_id,
        "tagId": tag_id,
    }


class JSONDefaultTests(unittest.TestCase):
    def test_whole_number_decimal_serializes_as_json_int_not_string(self):
        body = {"sortOrder": Decimal("1")}
        encoded = json.dumps(body, default=_json_default)
        self.assertEqual(encoded, '{"sortOrder": 1}')
        self.assertNotIn('"1"', encoded)

    def test_fractional_decimal_serializes_as_json_float(self):
        body = {"amount": Decimal("2.5")}
        encoded = json.dumps(body, default=_json_default)
        self.assertEqual(json.loads(encoded)["amount"], 2.5)

    def test_non_decimal_unserializable_value_still_stringified(self):
        class Weird:
            def __str__(self):
                return "weird-value"

        encoded = json.dumps({"x": Weird()}, default=_json_default)
        self.assertEqual(json.loads(encoded)["x"], "weird-value")


class ResponseLifeAreaRegressionTests(unittest.TestCase):
    def test_response_preserves_sort_order_as_number(self):
        # Regression for the exact live bug: real DynamoDB rows return sortOrder
        # as Decimal; the response body must decode back to an int, not a str,
        # or Swift's `LifeAreaDTO.sortOrder: Int` fails with a decode error.
        response = _response(200, {"lifeAreas": [{"name": "Work", "sortOrder": Decimal("1")}]})
        parsed = json.loads(response["body"])
        self.assertEqual(parsed["lifeAreas"][0]["sortOrder"], 1)
        self.assertIsInstance(parsed["lifeAreas"][0]["sortOrder"], int)


class TallyTagUsageTests(unittest.TestCase):
    U = "user-1"

    def test_empty_inputs_return_empty_dict(self):
        self.assertEqual(tally_tag_usage([], []), {})

    def test_task_joins_only(self):
        items = [_tasktag(self.U, "t1", "A"), _tasktag(self.U, "t2", "A")]
        counts = tally_tag_usage(items, [])
        self.assertEqual(counts["A"], {"taskCount": 2, "captureCount": 0})

    def test_capture_joins_only(self):
        items = [_capturetag(self.U, "c1", "B")]
        counts = tally_tag_usage([], items)
        self.assertEqual(counts["B"], {"taskCount": 0, "captureCount": 1})

    def test_task_and_capture_for_same_tag_sum_separately(self):
        tasktags = [_tasktag(self.U, "t1", "A")]
        capturetags = [_capturetag(self.U, "c1", "A"), _capturetag(self.U, "c2", "A")]
        counts = tally_tag_usage(tasktags, capturetags)
        self.assertEqual(counts["A"], {"taskCount": 1, "captureCount": 2})

    def test_multiple_tags_tallied_independently(self):
        tasktags = [_tasktag(self.U, "t1", "A"), _tasktag(self.U, "t1", "B")]
        capturetags = [_capturetag(self.U, "c1", "B")]
        counts = tally_tag_usage(tasktags, capturetags)
        self.assertEqual(counts["A"], {"taskCount": 1, "captureCount": 0})
        self.assertEqual(counts["B"], {"taskCount": 1, "captureCount": 1})

    def test_tagid_taken_from_last_sk_segment_not_middle(self):
        # taskId LAST-segment trap: the tag id is the final #-segment, never the taskId.
        counts = tally_tag_usage([_tasktag(self.U, "task-xyz", "tag-A")], [])
        self.assertIn("tag-A", counts)
        self.assertNotIn("task-xyz", counts)


class PlanTagMergeTests(unittest.TestCase):
    U = "user-1"
    LOSER = "L"
    SURV = "S"

    def test_loser_only_task_join_is_repointed(self):
        tasktags = [_tasktag(self.U, "t1", self.LOSER)]
        plan = plan_tag_merge(self.U, tasktags, [], self.LOSER, self.SURV)
        self.assertEqual(len(plan["writes"]), 1)
        self.assertEqual(plan["writes"][0]["SK"], f"TASKTAG#t1#{self.SURV}")
        self.assertEqual(plan["writes"][0]["tagId"], self.SURV)
        self.assertEqual(plan["deletes"], [{"PK": f"USER#{self.U}", "SK": f"TASKTAG#t1#{self.LOSER}"}])
        self.assertEqual(plan["stats"]["tasksRepointed"], 1)
        self.assertEqual(plan["stats"]["tasksDeduped"], 0)

    def test_survivor_only_join_leaves_loser_plan_empty(self):
        tasktags = [_tasktag(self.U, "t1", self.SURV)]
        plan = plan_tag_merge(self.U, tasktags, [], self.LOSER, self.SURV)
        self.assertEqual(plan["writes"], [])
        self.assertEqual(plan["deletes"], [])

    def test_item_carrying_both_is_deduped_not_duplicated(self):
        # The dedup case: a task carrying BOTH tags must end with exactly one row (survivor's),
        # so the loser row is deleted and NO survivor row is written.
        tasktags = [_tasktag(self.U, "t1", self.LOSER), _tasktag(self.U, "t1", self.SURV)]
        plan = plan_tag_merge(self.U, tasktags, [], self.LOSER, self.SURV)
        self.assertEqual(plan["writes"], [])
        self.assertEqual(plan["deletes"], [{"PK": f"USER#{self.U}", "SK": f"TASKTAG#t1#{self.LOSER}"}])
        self.assertEqual(plan["stats"]["tasksDeduped"], 1)
        self.assertEqual(plan["stats"]["tasksRepointed"], 0)

    def test_merge_spans_tasks_and_captures(self):
        tasktags = [_tasktag(self.U, "t1", self.LOSER)]
        capturetags = [
            _capturetag(self.U, "c1", self.LOSER),               # repoint
            _capturetag(self.U, "c2", self.LOSER),               # dedup (also carries survivor)
            _capturetag(self.U, "c2", self.SURV),
        ]
        plan = plan_tag_merge(self.U, tasktags, capturetags, self.LOSER, self.SURV)
        write_sks = sorted(w["SK"] for w in plan["writes"])
        self.assertEqual(write_sks, [f"CAPTURETAG#c1#{self.SURV}", f"TASKTAG#t1#{self.SURV}"])
        delete_sks = sorted(d["SK"] for d in plan["deletes"])
        self.assertEqual(delete_sks, [
            f"CAPTURETAG#c1#{self.LOSER}",
            f"CAPTURETAG#c2#{self.LOSER}",
            f"TASKTAG#t1#{self.LOSER}",
        ])
        self.assertEqual(plan["stats"]["tasksRepointed"], 1)
        self.assertEqual(plan["stats"]["capturesRepointed"], 1)
        self.assertEqual(plan["stats"]["capturesDeduped"], 1)

    def test_plan_never_touches_unrelated_tags(self):
        tasktags = [_tasktag(self.U, "t1", "OTHER")]
        plan = plan_tag_merge(self.U, tasktags, [], self.LOSER, self.SURV)
        self.assertEqual(plan["writes"], [])
        self.assertEqual(plan["deletes"], [])


class PlanTagCascadeTests(unittest.TestCase):
    U = "user-1"

    def test_cascade_deletes_all_junction_rows_for_tag_only(self):
        tasktags = [_tasktag(self.U, "t1", "X"), _tasktag(self.U, "t2", "Y")]
        capturetags = [_capturetag(self.U, "c1", "X")]
        plan = plan_tag_cascade(self.U, tasktags, capturetags, "X")
        delete_sks = sorted(d["SK"] for d in plan["deletes"])
        self.assertEqual(delete_sks, [f"CAPTURETAG#c1#X", f"TASKTAG#t1#X"])

    def test_cascade_of_unused_tag_is_empty(self):
        plan = plan_tag_cascade(self.U, [_tasktag(self.U, "t1", "Y")], [], "X")
        self.assertEqual(plan["deletes"], [])


# ---- Life Areas backend block: pure-function coverage -----------------------


def _area(area_id, name, sort_order, colour="🌱", archived=None):
    item = {
        "PK": "USER#u1",
        "SK": f"AREA#{area_id}",
        "entity": "AREA",
        "id": area_id,
        "userId": "u1",
        "name": name,
        "colour": colour,
        "sortOrder": Decimal(str(sort_order)),
    }
    if archived is not None:
        item["archived"] = archived
    return item


class PlanLifeAreaPatchTests(unittest.TestCase):
    def _existing(self, **over):
        base = {"name": "Work", "colour": "💼", "archived": False}
        base.update(over)
        return base

    # ---- allow-list -------------------------------------------------------
    def test_unknown_key_is_rejected_400(self):
        updates, err = plan_life_area_patch(self._existing(), {"sortOrder": 3})
        self.assertIsNone(updates)
        self.assertEqual(err[0], 400)

    def test_multiple_unknown_keys_named_in_message(self):
        updates, err = plan_life_area_patch(self._existing(), {"foo": 1, "bar": 2})
        self.assertIsNone(updates)
        self.assertEqual(err[0], 400)
        self.assertIn("bar", err[1])
        self.assertIn("foo", err[1])

    def test_empty_body_is_noop_not_error(self):
        updates, err = plan_life_area_patch(self._existing(), {})
        self.assertIsNone(err)
        self.assertEqual(updates, {})

    # ---- name -------------------------------------------------------------
    def test_name_trimmed_and_written(self):
        updates, err = plan_life_area_patch(self._existing(), {"name": "  Health  "})
        self.assertIsNone(err)
        self.assertEqual(updates, {"name": "Health"})

    def test_name_empty_after_trim_is_400(self):
        updates, err = plan_life_area_patch(self._existing(), {"name": "   "})
        self.assertIsNone(updates)
        self.assertEqual(err[0], 400)

    def test_name_non_string_is_400(self):
        updates, err = plan_life_area_patch(self._existing(), {"name": 5})
        self.assertIsNone(updates)
        self.assertEqual(err[0], 400)

    def test_name_unchanged_after_trim_is_noop(self):
        updates, err = plan_life_area_patch(self._existing(), {"name": "  Work  "})
        self.assertIsNone(err)
        self.assertEqual(updates, {})

    # ---- colour (the emoji field) ----------------------------------------
    def test_colour_trimmed_and_written(self):
        updates, err = plan_life_area_patch(self._existing(), {"colour": " 🏃 "})
        self.assertIsNone(err)
        self.assertEqual(updates, {"colour": "🏃"})

    def test_colour_empty_after_trim_is_400(self):
        updates, err = plan_life_area_patch(self._existing(), {"colour": "  "})
        self.assertIsNone(updates)
        self.assertEqual(err[0], 400)

    def test_colour_non_string_is_400(self):
        updates, err = plan_life_area_patch(self._existing(), {"colour": True})
        self.assertIsNone(updates)
        self.assertEqual(err[0], 400)

    def test_colour_unchanged_is_noop(self):
        updates, err = plan_life_area_patch(self._existing(), {"colour": "💼"})
        self.assertIsNone(err)
        self.assertEqual(updates, {})

    # ---- archived (real boolean only) ------------------------------------
    def test_archived_true_written(self):
        updates, err = plan_life_area_patch(self._existing(), {"archived": True})
        self.assertIsNone(err)
        self.assertEqual(updates, {"archived": True})

    def test_archived_string_true_is_400(self):
        updates, err = plan_life_area_patch(self._existing(), {"archived": "true"})
        self.assertIsNone(updates)
        self.assertEqual(err[0], 400)

    def test_archived_int_is_400(self):
        # isinstance(1, bool) is False in Python, so an int must be rejected too.
        updates, err = plan_life_area_patch(self._existing(), {"archived": 1})
        self.assertIsNone(updates)
        self.assertEqual(err[0], 400)

    def test_archived_missing_on_existing_read_as_false_noop(self):
        # existing has no archived attribute -> treated as False -> archived:false is a no-op.
        existing = {"name": "Work", "colour": "💼"}
        updates, err = plan_life_area_patch(existing, {"archived": False})
        self.assertIsNone(err)
        self.assertEqual(updates, {})

    def test_archived_false_when_currently_true_is_written(self):
        updates, err = plan_life_area_patch(self._existing(archived=True), {"archived": False})
        self.assertIsNone(err)
        self.assertEqual(updates, {"archived": False})

    def test_multiple_fields_at_once(self):
        updates, err = plan_life_area_patch(
            self._existing(), {"name": "Gym", "colour": "🏋️", "archived": True}
        )
        self.assertIsNone(err)
        self.assertEqual(updates, {"name": "Gym", "colour": "🏋️", "archived": True})


class FindNameConflictTests(unittest.TestCase):
    def test_no_conflict_returns_none(self):
        areas = [_area("a", "Work", 1), _area("b", "Home", 2)]
        self.assertIsNone(find_name_conflict(areas, "Health"))

    def test_conflict_against_live_area_archived_false(self):
        areas = [_area("a", "Work", 1, archived=False)]
        c = find_name_conflict(areas, "Work")
        self.assertEqual(c["id"], "a")
        self.assertEqual(c["name"], "Work")
        self.assertIs(c["archived"], False)

    def test_conflict_against_archived_area_archived_true(self):
        areas = [_area("a", "Work", 1, archived=True)]
        c = find_name_conflict(areas, "Work")
        self.assertIs(c["archived"], True)

    def test_conflict_row_with_no_archived_attribute_reads_false(self):
        # The seeded shape: real rows predate the field. missing-means-false must hold here.
        areas = [_area("a", "Work", 1)]  # no archived attribute at all
        self.assertNotIn("archived", areas[0])
        c = find_name_conflict(areas, "Work")
        self.assertIs(c["archived"], False)

    def test_exclude_id_skips_self_on_rename(self):
        # Renaming area "a" to its own current name must not self-conflict.
        areas = [_area("a", "Work", 1)]
        self.assertIsNone(find_name_conflict(areas, "Work", exclude_id="a"))

    def test_rename_onto_a_different_archived_area_reports_archived_true(self):
        areas = [_area("a", "Work", 1), _area("b", "OldGym", 2, archived=True)]
        c = find_name_conflict(areas, "OldGym", exclude_id="a")
        self.assertEqual(c["id"], "b")
        self.assertIs(c["archived"], True)


class NextSortOrderTests(unittest.TestCase):
    def test_max_plus_one(self):
        areas = [_area("a", "A", 0), _area("b", "B", 5), _area("c", "C", 3)]
        self.assertEqual(next_sort_order(areas), 6)

    def test_handles_decimal_sort_order(self):
        # DynamoDB returns Number attributes as Decimal — must not blow up or return a Decimal.
        areas = [_area("a", "A", Decimal("8"))]
        result = next_sort_order(areas)
        self.assertEqual(result, 9)
        self.assertIsInstance(result, int)

    def test_no_areas_returns_zero(self):
        self.assertEqual(next_sort_order([]), 0)

    def test_missing_sort_order_treated_as_zero(self):
        areas = [{"id": "a", "name": "A"}]  # no sortOrder
        self.assertEqual(next_sort_order(areas), 1)


class ValidateReorderTests(unittest.TestCase):
    CUR = ["a", "b", "c"]

    def test_exact_set_is_valid(self):
        self.assertIsNone(validate_reorder(["c", "a", "b"], self.CUR))

    def test_missing_id_is_400(self):
        err = validate_reorder(["a", "b"], self.CUR)
        self.assertEqual(err[0], 400)
        self.assertIn("c", err[1])

    def test_extra_unknown_id_is_400(self):
        err = validate_reorder(["a", "b", "c", "zzz"], self.CUR)
        self.assertEqual(err[0], 400)
        self.assertIn("zzz", err[1])

    def test_duplicate_id_is_400(self):
        err = validate_reorder(["a", "b", "b"], self.CUR)
        self.assertEqual(err[0], 400)
        self.assertIn("b", err[1])

    def test_non_list_is_400(self):
        self.assertEqual(validate_reorder(None, self.CUR)[0], 400)
        self.assertEqual(validate_reorder("a,b,c", self.CUR)[0], 400)

    def test_empty_order_against_nonempty_current_is_400(self):
        err = validate_reorder([], self.CUR)
        self.assertEqual(err[0], 400)


if __name__ == "__main__":
    unittest.main()
