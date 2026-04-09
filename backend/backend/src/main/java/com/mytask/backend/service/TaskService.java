package com.mytask.backend.service;

import com.mytask.backend.enums.Importance;
import com.mytask.backend.enums.Priority;
import com.mytask.backend.model.PomodoroSession;
import com.mytask.backend.model.Task;
import com.mytask.backend.repository.PomodoroSessionRepository;
import com.mytask.backend.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final PomodoroSessionRepository pomodoroSessionRepository;

    public List<Task> getAllTasks() {
        return taskRepository.findAll();
    }

    public Task getTaskById(Long id) {
        return taskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found with id: " + id));
    }

    public Task createTask(Task task) {
        return taskRepository.save(task);
    }

    public Task updateTask(Long id, Task updatedTask) {
        Task existing = getTaskById(id);
        existing.setTitle(updatedTask.getTitle());
        existing.setDescription(updatedTask.getDescription());
        existing.setPriority(updatedTask.getPriority());
        existing.setImportance(updatedTask.getImportance());
        existing.setStatus(updatedTask.getStatus());
        existing.setDueDate(updatedTask.getDueDate());
        existing.setChecked(updatedTask.isChecked());
        return taskRepository.save(existing);
    }

    public Task toggleChecked(Long id) {
        Task task = getTaskById(id);
        task.setChecked(!task.isChecked());
        return taskRepository.save(task);
    }

    public void deleteTask(Long id) {
        // Hapus semua pomodoro session terkait dulu
        List<PomodoroSession> sessions = pomodoroSessionRepository.findByTaskId(id);
        pomodoroSessionRepository.deleteAll(sessions);
        // Baru hapus task
        taskRepository.deleteById(id);
    }

    // Eisenhower Matrix — 4 kuadran
    public Map<String, List<Task>> getEisenhowerMatrix() {
        Map<String, List<Task>> matrix = new HashMap<>();
        matrix.put("DO_FIRST",    taskRepository.findByPriorityAndImportance(Priority.URGENT,     Importance.IMPORTANT));
        matrix.put("SCHEDULE",    taskRepository.findByPriorityAndImportance(Priority.NOT_URGENT, Importance.IMPORTANT));
        matrix.put("DELEGATE",    taskRepository.findByPriorityAndImportance(Priority.URGENT,     Importance.NOT_IMPORTANT));
        matrix.put("ELIMINATE",   taskRepository.findByPriorityAndImportance(Priority.NOT_URGENT, Importance.NOT_IMPORTANT));
        return matrix;
    }

    // Calendar — task dalam 1 bulan tertentu
    public List<Task> getTasksByMonth(int year, int month) {
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end   = start.withDayOfMonth(start.lengthOfMonth());
        return taskRepository.findByDueDateBetween(start, end);
    }

    // Checklist — hanya task yang belum dicentang
    public List<Task> getUncheckedTasks() {
        return taskRepository.findByCheckedFalse();
    }
}