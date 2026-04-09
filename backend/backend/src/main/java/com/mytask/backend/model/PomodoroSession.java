package com.mytask.backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "pomodoro_sessions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PomodoroSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "task_id", foreignKey = @ForeignKey(name = "FKnpvatx1dl04up2vkdpp8g6iif"))
    private Task task;

    private int durationMinutes = 25;

    private LocalDateTime startedAt;

    private LocalDateTime endedAt;

    private boolean completed = false;
}