package com.mytask.backend.controller;

import com.mytask.backend.dto.HabitCalendarResponse;
import com.mytask.backend.model.Habit;
import com.mytask.backend.model.HabitLog;
import com.mytask.backend.service.HabitService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/habits")
@RequiredArgsConstructor
public class HabitController {

    private final HabitService habitService;

    @GetMapping
    public ResponseEntity<List<HabitCalendarResponse>> getAllHabits() {
        return ResponseEntity.ok(habitService.getAllHabitsWithTodayStatus());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Habit> getHabitById(@PathVariable Long id) {
        return ResponseEntity.ok(habitService.getHabitById(id));
    }

    // Untuk Calendar
    @GetMapping("/calendar")
    public ResponseEntity<List<HabitCalendarResponse>> getHabitsForMonth(
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(habitService.getHabitsForMonth(year, month));
    }

    // Log habit per hari
    @GetMapping("/{id}/logs")
    public ResponseEntity<List<HabitLog>> getLogs(@PathVariable Long id) {
        return ResponseEntity.ok(habitService.getLogsByHabit(id));
    }

    @PostMapping
    public ResponseEntity<Habit> createHabit(@Valid @RequestBody Habit habit) {
        return ResponseEntity.ok(habitService.createHabit(habit));
    }

    @PostMapping("/{id}/log")
    public ResponseEntity<HabitLog> toggleLog(
            @PathVariable Long id,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody(required = false) Map<String, String> body) {
        LocalDate logDate = date != null ? date : LocalDate.now();
        String notes = body != null ? body.get("notes") : null;
        return ResponseEntity.ok(habitService.toggleLog(id, logDate, notes));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Habit> updateHabit(
            @PathVariable Long id,
            @Valid @RequestBody Habit habit) {
        return ResponseEntity.ok(habitService.updateHabit(id, habit));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteHabit(@PathVariable Long id) {
        habitService.deleteHabit(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/log/water")
    public ResponseEntity<HabitLog> updateWaterLog(
            @PathVariable Long id,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody Map<String, Integer> body) {
        LocalDate logDate = date != null ? date : LocalDate.now();
        int amount = body.getOrDefault("amount", 0);
        return ResponseEntity.ok(habitService.updateWaterLog(id, logDate, amount));
    }
}