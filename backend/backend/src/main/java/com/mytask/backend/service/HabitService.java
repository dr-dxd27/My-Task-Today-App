package com.mytask.backend.service;

import com.mytask.backend.dto.HabitCalendarResponse;
import com.mytask.backend.enums.DurationType;
import com.mytask.backend.model.Habit;
import com.mytask.backend.model.HabitLog;
import com.mytask.backend.repository.HabitLogRepository;
import com.mytask.backend.repository.HabitRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class HabitService {

    private final HabitRepository habitRepository;
    private final HabitLogRepository habitLogRepository;

    private LocalDate calculateEndDate(LocalDate startDate, DurationType type, Integer value) {
        if (type == DurationType.ALL_TIME
                || type == DurationType.CUSTOM
                || value == null) return null;
        return switch (type) {
            case DAY  -> startDate.plusDays(value);
            case WEEK -> startDate.plusWeeks(value);
            case YEAR -> startDate.plusYears(value);
            default   -> null;
        };
    }

    // Cek apakah habit CUSTOM aktif pada hari tertentu
    private boolean isHabitActiveOnDay(Habit habit, LocalDate date) {
        if (habit.getDurationType() != DurationType.CUSTOM) return true;
        if (habit.getCustomDays() == null || habit.getCustomDays().isEmpty()) return false;
        // Ambil nama hari dalam bahasa Inggris uppercase, contoh: "MONDAY"
        String dayName = date.getDayOfWeek()
                .getDisplayName(TextStyle.FULL, Locale.ENGLISH)
                .toUpperCase();
        return habit.getCustomDays().contains(dayName);
    }

    public List<Habit> getAllHabits() {
        return habitRepository.findByActiveTrue();
    }

    public Habit getHabitById(Long id) {
        return habitRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Habit not found with id: " + id));
    }

    public Habit createHabit(Habit habit) {
        habit.setStartDate(
                habit.getStartDate() != null ? habit.getStartDate() : LocalDate.now());
        habit.setEndDate(calculateEndDate(
                habit.getStartDate(), habit.getDurationType(), habit.getDurationValue()));
        return habitRepository.save(habit);
    }

    public Habit updateHabit(Long id, Habit updated) {
        Habit existing = getHabitById(id);
        existing.setName(updated.getName());
        existing.setMotto(updated.getMotto());
        existing.setNotifTimes(updated.getNotifTimes());
        existing.setDurationType(updated.getDurationType());
        existing.setDurationValue(updated.getDurationValue());
        existing.setCustomDays(updated.getCustomDays());
        existing.setTemplate(updated.getTemplate());
        existing.setWaterTargetAmount(updated.getWaterTargetAmount());
        existing.setWaterTargetUnit(updated.getWaterTargetUnit());
        existing.setEndDate(calculateEndDate(
                existing.getStartDate(), updated.getDurationType(), updated.getDurationValue()));
        return habitRepository.save(existing);
    }

    public void deleteHabit(Long id) {
        Habit habit = getHabitById(id);
        habit.setActive(false);
        habitRepository.save(habit);
    }

    public HabitLog toggleLog(Long habitId, LocalDate date, String notes) {
        Habit habit = getHabitById(habitId);
        Optional<HabitLog> existing =
                habitLogRepository.findByHabitIdAndLogDate(habitId, date);

        if (existing.isPresent()) {
            HabitLog log = existing.get();
            log.setCompleted(!log.isCompleted());
            log.setNotes(notes);
            return habitLogRepository.save(log);
        } else {
            HabitLog log = new HabitLog();
            log.setHabit(habit);
            log.setLogDate(date);
            log.setCompleted(true);
            log.setNotes(notes);
            return habitLogRepository.save(log);
        }
    }

    public List<HabitLog> getLogsByHabit(Long habitId) {
        return habitLogRepository.findByHabitId(habitId);
    }

    public List<HabitCalendarResponse> getHabitsForMonth(int year, int month) {
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end   = start.withDayOfMonth(start.lengthOfMonth());

        List<Habit> rangedHabits = habitRepository
                .findByActiveTrueAndStartDateLessThanEqualAndEndDateGreaterThanEqual(end, start);
        List<Habit> allTimeAndCustomHabits =
                habitRepository.findByActiveTrueAndEndDateIsNull();

        List<Habit> habits = new ArrayList<>(rangedHabits);
        allTimeAndCustomHabits.stream()
                .filter(h -> !habits.contains(h))
                .forEach(habits::add);

        List<HabitLog> logsThisMonth =
                habitLogRepository.findByLogDateBetween(start, end);
        LocalDate today = LocalDate.now();

        return habits.stream()
                // Filter CUSTOM: hanya tampilkan jika hari ini ada di customDays
                .filter(habit -> isHabitActiveOnDay(habit, today))
                .map(habit -> {
                    Optional<HabitLog> todayLog = logsThisMonth.stream()
                            .filter(log -> log.getHabit().getId().equals(habit.getId())
                                    && log.getLogDate().equals(today))
                            .findFirst();

                    boolean completedToday = todayLog
                            .map(HabitLog::isCompleted)
                            .orElse(false);

                    int currentWaterAmount = todayLog
                            .map(log -> log.getCurrentAmount() != null
                                    ? log.getCurrentAmount() : 0)
                            .orElse(0);
                    return new HabitCalendarResponse(
                            habit.getId(),
                            habit.getName(),
                            habit.getMotto(),
                            habit.getTemplate(),
                            habit.getDurationType(),
                            habit.getCustomDays(),
                            habit.getStartDate(),
                            habit.getEndDate(),
                            habit.getNotifTimes(),
                            habit.getWaterTargetAmount(),
                            habit.getWaterTargetUnit(),
                            currentWaterAmount,
                            completedToday
                    );
                }).toList();
    }

    public List<HabitCalendarResponse> getAllHabitsWithTodayStatus() {
        LocalDate today = LocalDate.now();
        List<Habit> habits = habitRepository.findByActiveTrue();
        List<HabitLog> todayLogs = habitLogRepository.findByLogDateBetween(today, today);

        return habits.stream()
                .filter(habit -> isHabitActiveOnDay(habit, today))
                .map(habit -> {
                    Optional<HabitLog> todayLog = todayLogs.stream()
                            .filter(log -> log.getHabit().getId().equals(habit.getId()))
                            .findFirst();

                    boolean completedToday = todayLog
                            .map(HabitLog::isCompleted)
                            .orElse(false);

                    int currentWaterAmount = todayLog
                            .map(log -> log.getCurrentAmount() != null
                                    ? log.getCurrentAmount() : 0)
                            .orElse(0);
                    return new HabitCalendarResponse(
                            habit.getId(),
                            habit.getName(),
                            habit.getMotto(),
                            habit.getTemplate(),
                            habit.getDurationType(),
                            habit.getCustomDays(),
                            habit.getStartDate(),
                            habit.getEndDate(),
                            habit.getNotifTimes(),
                            habit.getWaterTargetAmount(),
                            habit.getWaterTargetUnit(),
                            currentWaterAmount,
                            completedToday
                    );
                }).toList();
    }

    public HabitLog updateWaterLog(Long habitId, LocalDate date, int amount) {
        Habit habit = getHabitById(habitId);
        Optional<HabitLog> existing =
                habitLogRepository.findByHabitIdAndLogDate(habitId, date);

        HabitLog log;
        if (existing.isPresent()) {
            log = existing.get();
        } else {
            log = new HabitLog();
            log.setHabit(habit);
            log.setLogDate(date);
        }

        // Update jumlah — tidak boleh negatif
        int newAmount = Math.max(0, amount);
        log.setCurrentAmount(newAmount);

        // Auto complete jika sudah mencapai target
        if (habit.getWaterTargetAmount() != null) {
            log.setCompleted(newAmount >= habit.getWaterTargetAmount());
        }

        return habitLogRepository.save(log);
    }
}