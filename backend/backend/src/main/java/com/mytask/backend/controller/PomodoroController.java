package com.mytask.backend.controller;

import com.mytask.backend.dto.PomodoroRecordResponse;
import com.mytask.backend.dto.PomodoroStatsResponse;
import com.mytask.backend.model.PomodoroSession;
import com.mytask.backend.service.PomodoroService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/pomodoro")
@RequiredArgsConstructor
public class PomodoroController {

    private final PomodoroService pomodoroService;

    @PostMapping("/start")
    public ResponseEntity<PomodoroSession> startSession(
            @RequestBody Map<String, Object> body) {
        Long taskId = body.get("taskId") != null
                ? Long.valueOf(body.get("taskId").toString()) : null;
        int duration = body.get("durationMinutes") != null
                ? Integer.parseInt(body.get("durationMinutes").toString()) : 25;
        return ResponseEntity.ok(pomodoroService.startSession(taskId, duration));
    }

    @PutMapping("/{id}/complete")
    public ResponseEntity<PomodoroSession> completeSession(@PathVariable Long id) {
        return ResponseEntity.ok(pomodoroService.completeSession(id));
    }

    // Trends — WEEK, MONTH, YEAR
    @GetMapping("/stats")
    public ResponseEntity<PomodoroStatsResponse> getStats(
            @RequestParam(defaultValue = "WEEK") String range) {
        return ResponseEntity.ok(pomodoroService.getStats(range));
    }

    // Focus Records
    @GetMapping("/records")
    public ResponseEntity<List<PomodoroRecordResponse>> getRecords() {
        return ResponseEntity.ok(pomodoroService.getRecords());
    }
}