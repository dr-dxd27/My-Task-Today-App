package com.mytask.backend.repository;

import com.mytask.backend.model.Habit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface HabitRepository extends JpaRepository<Habit, Long> {

    // Ambil habit yang aktif
    List<Habit> findByActiveTrue();

    // Habit yang berlaku pada bulan tertentu (untuk Calendar)
    // startDate <= endOfMonth AND (endDate >= startOfMonth OR endDate IS NULL)
    List<Habit> findByActiveTrueAndStartDateLessThanEqualAndEndDateGreaterThanEqual(
            LocalDate endOfMonth, LocalDate startOfMonth);

    // Habit ALL_TIME yang aktif (endDate null)
    List<Habit> findByActiveTrueAndEndDateIsNull();
}