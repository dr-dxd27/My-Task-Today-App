package com.mytask.backend.repository;

import com.mytask.backend.model.HabitLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface HabitLogRepository extends JpaRepository<HabitLog, Long> {

    List<HabitLog> findByHabitId(Long habitId);

    List<HabitLog> findByHabitIdAndLogDateBetween(Long habitId, LocalDate start, LocalDate end);

    Optional<HabitLog> findByHabitIdAndLogDate(Long habitId, LocalDate logDate);

    // Semua log dalam 1 bulan (untuk Calendar)
    List<HabitLog> findByLogDateBetween(LocalDate start, LocalDate end);
}