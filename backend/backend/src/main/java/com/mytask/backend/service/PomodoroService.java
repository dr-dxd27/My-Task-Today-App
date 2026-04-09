package com.mytask.backend.service;

import com.mytask.backend.model.PomodoroSession;
import com.mytask.backend.model.Task;
import com.mytask.backend.repository.PomodoroSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PomodoroService {

    private final PomodoroSessionRepository pomodoroSessionRepository;
    private final TaskService taskService;

    public PomodoroSession startSession(Long taskId, int durationMinutes) {
        Task task = taskService.getTaskById(taskId);
        PomodoroSession session = PomodoroSession.builder()
                .task(task)
                .durationMinutes(durationMinutes)
                .startedAt(LocalDateTime.now())
                .completed(false)
                .build();
        return pomodoroSessionRepository.save(session);
    }

    public PomodoroSession completeSession(Long sessionId) {
        PomodoroSession session = pomodoroSessionRepository.findById(sessionId)
                .orElseThrow(() -> new RuntimeException("Session not found: " + sessionId));
        session.setCompleted(true);
        session.setEndedAt(LocalDateTime.now());
        return pomodoroSessionRepository.save(session);
    }

    public List<PomodoroSession> getSessionsByTask(Long taskId) {
        return pomodoroSessionRepository.findByTaskId(taskId);
    }

    public List<PomodoroSession> getAllCompletedSessions() {
        return pomodoroSessionRepository.findByCompletedTrue();
    }
}