package main

import (
	"testing"
	"time"
)

func TestGetWeekAndDayOfCycle(t *testing.T) {
	perth, err := time.LoadLocation("Australia/Perth")
	if err != nil {
		t.Errorf(err.Error())
	}

	firstDayOfCycle := time.Date(2024, 1, 1, 0, 0, 0, 0, perth)

	if getWeekOfCycle(time.Date(2024, 12, 15, 0, 0, 0, 0, perth), firstDayOfCycle) != secondWeek {
		t.Errorf("expected: second, got: first")
	}

	if getWeekOfCycle(time.Date(2024, 12, 16, 0, 0, 0, 0, perth), firstDayOfCycle) != firstWeek {
		t.Errorf("expected: first, got: second")
	}

	if getWeekOfCycle(time.Date(2024, 12, 25, 0, 0, 0, 0, perth), firstDayOfCycle) != secondWeek {
		t.Errorf("expected: second, got: first")
	}

	if getWeekOfCycle(time.Date(2025, 1, 2, 0, 0, 0, 0, perth), firstDayOfCycle) != firstWeek {
		t.Errorf("expected: first, got: second")
	}

	if getWeekOfCycle(time.Date(2024, 1, 2, 0, 0, 0, 0, perth), firstDayOfCycle) != firstWeek {
		t.Errorf("expected: first, got: second")
	}

	if getWeekOfCycle(time.Date(2024, 1, 3, 0, 0, 0, 0, perth), firstDayOfCycle) != firstWeek {
		t.Errorf("expected: first, got: second")
	}

	if getWeekOfCycle(time.Date(2024, 1, 4, 0, 0, 0, 0, perth), firstDayOfCycle) != firstWeek {
		t.Errorf("expected: first, got: second")
	}

	if getWeekOfCycle(time.Date(2024, 1, 5, 0, 0, 0, 0, perth), firstDayOfCycle) != firstWeek {
		t.Errorf("expected: first, got: second")
	}

	if getWeekOfCycle(time.Date(2024, 1, 7, 0, 0, 0, 0, perth), firstDayOfCycle) != firstWeek {
		t.Errorf("expected: first, got: second")
	}

	if getWeekOfCycle(time.Date(2024, 1, 9, 0, 0, 0, 0, perth), firstDayOfCycle) != secondWeek {
		t.Errorf("expected: second, got: one")
	}
}
