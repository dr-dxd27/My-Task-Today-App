package com.mytask.backend.repository;

import com.mytask.backend.model.PomodoroSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PomodoroSessionRepository extends JpaRepository<PomodoroSession, Long> {

    List<PomodoroSession> findByTaskId(Long taskId);

    List<PomodoroSession> findByCompletedTrue();

    // Untuk trends & records berdasarkan range tanggal
    List<PomodoroSession> findByCompletedTrueAndStartedAtBetween(
            LocalDateTime start, LocalDateTime end);

    // Untuk records terbaru
    List<PomodoroSession> findTop20ByCompletedTrueOrderByStartedAtDesc();
}