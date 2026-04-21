package com.mytask.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@AllArgsConstructor
public class PomodoroStatsResponse {
    private String range;           // WEEK, MONTH, YEAR
    private int totalSessions;      // total sesi dalam range
    private int totalMinutes;       // total menit fokus
    private List<PomodoroStatDay> dailyStats; // data per hari

    @Getter
    @Setter
    @AllArgsConstructor
    public static class PomodoroStatDay {
        private String date;        // format: yyyy-MM-dd
        private String label;       // label tampilan: "Sen", "1", "Jan"
        private int sessionCount;   // jumlah sesi
        private int totalMinutes;   // total menit
    }
}