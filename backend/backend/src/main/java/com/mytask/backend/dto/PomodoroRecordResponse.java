package com.mytask.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class PomodoroRecordResponse {
    private Long id;
    private String taskTitle;   // null jika tanpa task
    private int durationMinutes;
    private String startedAt;   // format: yyyy-MM-dd HH:mm
    private String endedAt;
}