package com.mytask.backend.service;

import com.mytask.backend.dto.PomodoroRecordResponse;
import com.mytask.backend.dto.PomodoroStatsResponse;
import com.mytask.backend.model.PomodoroSession;
import com.mytask.backend.repository.PomodoroSessionRepository;
import com.mytask.backend.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PomodoroService {

    private final PomodoroSessionRepository pomodoroSessionRepository;
    private final TaskRepository taskRepository;

    public PomodoroSession startSession(Long taskId, int duration) {
        PomodoroSession session = new PomodoroSession();
        if (taskId != null) {
            session.setTask(taskRepository.findById(taskId).orElse(null));
        }
        session.setDurationMinutes(duration);
        session.setStartedAt(LocalDateTime.now());
        session.setCompleted(false);
        return pomodoroSessionRepository.save(session);
    }

    public PomodoroSession completeSession(Long sessionId) {
        PomodoroSession session = pomodoroSessionRepository.findById(sessionId)
                .orElseThrow(() -> new RuntimeException("Session not found"));
        session.setEndedAt(LocalDateTime.now());
        session.setCompleted(true);
        return pomodoroSessionRepository.save(session);
    }

    // Stats untuk Trends
    public PomodoroStatsResponse getStats(String range) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime start;
        List<PomodoroStatsResponse.PomodoroStatDay> dailyStats;

        switch (range.toUpperCase()) {
            case "MONTH" -> start = now.minusDays(29).toLocalDate().atStartOfDay();
            case "YEAR"  -> start = now.minusMonths(11).withDayOfMonth(1).toLocalDate().atStartOfDay();
            default      -> start = now.minusDays(6).toLocalDate().atStartOfDay(); // WEEK
        }

        List<PomodoroSession> sessions = pomodoroSessionRepository
                .findByCompletedTrueAndStartedAtBetween(start, now);

        dailyStats = switch (range.toUpperCase()) {
            case "MONTH" -> buildDailyStats(sessions, start.toLocalDate(), 30);
            case "YEAR"  -> buildMonthlyStats(sessions, start.toLocalDate(), 12);
            default      -> buildDailyStats(sessions, start.toLocalDate(), 7);
        };

        int totalSessions = sessions.size();
        int totalMinutes = sessions.stream()
                .mapToInt(PomodoroSession::getDurationMinutes).sum();

        return new PomodoroStatsResponse(range.toUpperCase(), totalSessions,
                totalMinutes, dailyStats);
    }

    private List<PomodoroStatsResponse.PomodoroStatDay> buildDailyStats(
            List<PomodoroSession> sessions, LocalDate startDate, int days) {

        // Group sessions by date
        Map<LocalDate, List<PomodoroSession>> grouped = sessions.stream()
                .collect(Collectors.groupingBy(
                        s -> s.getStartedAt().toLocalDate()));

        String[] dayLabels = {"Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"};
        List<PomodoroStatsResponse.PomodoroStatDay> result = new ArrayList<>();

        for (int i = 0; i < days; i++) {
            LocalDate date = startDate.plusDays(i);
            List<PomodoroSession> daySessions = grouped.getOrDefault(date, List.of());
            String label = days == 7
                    ? dayLabels[date.getDayOfWeek().getValue() % 7]
                    : String.valueOf(date.getDayOfMonth());
            result.add(new PomodoroStatsResponse.PomodoroStatDay(
                    date.toString(),
                    label,
                    daySessions.size(),
                    daySessions.stream().mapToInt(PomodoroSession::getDurationMinutes).sum()
            ));
        }
        return result;
    }

    private List<PomodoroStatsResponse.PomodoroStatDay> buildMonthlyStats(
            List<PomodoroSession> sessions, LocalDate startDate, int months) {

        Map<String, List<PomodoroSession>> grouped = sessions.stream()
                .collect(Collectors.groupingBy(s -> {
                    LocalDate d = s.getStartedAt().toLocalDate();
                    return d.getYear() + "-" + String.format("%02d", d.getMonthValue());
                }));

        String[] monthLabels = {"Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
                "Jul", "Agu", "Sep", "Okt", "Nov", "Des"};
        List<PomodoroStatsResponse.PomodoroStatDay> result = new ArrayList<>();

        for (int i = 0; i < months; i++) {
            LocalDate date = startDate.plusMonths(i);
            String key = date.getYear() + "-" + String.format("%02d", date.getMonthValue());
            List<PomodoroSession> monthSessions = grouped.getOrDefault(key, List.of());
            result.add(new PomodoroStatsResponse.PomodoroStatDay(
                    date.toString(),
                    monthLabels[date.getMonthValue() - 1],
                    monthSessions.size(),
                    monthSessions.stream().mapToInt(PomodoroSession::getDurationMinutes).sum()
            ));
        }
        return result;
    }

    // Records — 20 sesi terbaru
    public List<PomodoroRecordResponse> getRecords() {
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
        return pomodoroSessionRepository
                .findTop20ByCompletedTrueOrderByStartedAtDesc()
                .stream()
                .map(s -> new PomodoroRecordResponse(
                        s.getId(),
                        s.getTask() != null ? s.getTask().getTitle() : null,
                        s.getDurationMinutes(),
                        s.getStartedAt() != null ? s.getStartedAt().format(fmt) : "-",
                        s.getEndedAt() != null ? s.getEndedAt().format(fmt) : "-"
                )).toList();
    }
}