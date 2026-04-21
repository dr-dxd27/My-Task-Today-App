package com.mytask.backend.model;

import com.mytask.backend.enums.DurationType;
import com.mytask.backend.enums.HabitTemplate;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "habits")
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class Habit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    private String name;

    @Column(columnDefinition = "TEXT")
    private String motto;

    @ElementCollection
    @CollectionTable(name = "habit_notif_times",
            joinColumns = @JoinColumn(name = "habit_id"))
    @Column(name = "notif_time")
    private List<String> notifTimes;

    @Enumerated(EnumType.STRING)
    private DurationType durationType = DurationType.ALL_TIME;

    private Integer durationValue;

    // Untuk CUSTOM — hari yang dipilih, contoh: ["MONDAY","WEDNESDAY","FRIDAY"]
    @ElementCollection
    @CollectionTable(name = "habit_custom_days",
            joinColumns = @JoinColumn(name = "habit_id"))
    @Column(name = "day_of_week")
    private List<String> customDays;

    @Enumerated(EnumType.STRING)
    private HabitTemplate template = HabitTemplate.CUSTOM;

    private Integer waterTargetAmount;
    private String waterTargetUnit;

    @Column(nullable = false)
    private LocalDate startDate;

    private LocalDate endDate;

    @Column(nullable = false)
    private boolean active = true;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}