package com.mytask.backend.controller;

import com.mytask.backend.model.Task;
import com.mytask.backend.service.TaskService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @GetMapping
    public ResponseEntity<List<Task>> getAllTasks() {
        return ResponseEntity.ok(taskService.getAllTasks());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Task> getTaskById(@PathVariable Long id) {
        return ResponseEntity.ok(taskService.getTaskById(id));
    }

    @GetMapping("/matrix")
    public ResponseEntity<Map<String, List<Task>>> getMatrix() {
        return ResponseEntity.ok(taskService.getEisenhowerMatrix());
    }

    @GetMapping("/calendar")
    public ResponseEntity<List<Task>> getByMonth(
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(taskService.getTasksByMonth(year, month));
    }

    @GetMapping("/checklist")
    public ResponseEntity<List<Task>> getUnchecked() {
        return ResponseEntity.ok(taskService.getUncheckedTasks());
    }

    @PostMapping
    public ResponseEntity<Task> createTask(@Valid @RequestBody Task task) {
        return ResponseEntity.ok(taskService.createTask(task));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Task> updateTask(
            @PathVariable Long id,
            @Valid @RequestBody Task task) {
        return ResponseEntity.ok(taskService.updateTask(id, task));
    }

    @PatchMapping("/{id}/check")
    public ResponseEntity<Task> toggleCheck(@PathVariable Long id) {
        return ResponseEntity.ok(taskService.toggleChecked(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        taskService.deleteTask(id);
        return ResponseEntity.noContent().build();
    }
}