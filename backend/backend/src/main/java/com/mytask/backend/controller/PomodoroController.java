package com.mytask.backend.controller;

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
    public ResponseEntity<PomodoroSession> startSession(@RequestBody Map<String, Object> body) {
        Long taskId = Long.valueOf(body.get("taskId").toString());
        int duration = body.containsKey("durationMinutes")
                ? (int) body.get("durationMinutes") : 25;
        return ResponseEntity.ok(pomodoroService.startSession(taskId, duration));
    }

    @PutMapping("/{id}/complete")
    public ResponseEntity<PomodoroSession> completeSession(@PathVariable Long id) {
        return ResponseEntity.ok(pomodoroService.completeSession(id));
    }

    @GetMapping("/task/{taskId}")
    public ResponseEntity<List<PomodoroSession>> getByTask(@PathVariable Long taskId) {
        return ResponseEntity.ok(pomodoroService.getSessionsByTask(taskId));
    }

    @GetMapping("/completed")
    public ResponseEntity<List<PomodoroSession>> getCompleted() {
        return ResponseEntity.ok(pomodoroService.getAllCompletedSessions());
    }
}