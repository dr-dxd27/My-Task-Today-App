package com.mytask.backend.dto;

import com.mytask.backend.enums.DurationType;
import com.mytask.backend.enums.HabitTemplate;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.util.List;

@Getter
@Setter
@AllArgsConstructor
public class HabitCalendarResponse {
    private Long id;
    private String name;
    private String motto;
    private HabitTemplate template;
    private DurationType durationType;
    private List<String> customDays;
    private LocalDate startDate;
    private LocalDate endDate;
    private List<String> notifTimes;
    private Integer waterTargetAmount;
    private String waterTargetUnit;
    private Integer currentWaterAmount;
    private boolean completedToday;
}