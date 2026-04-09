package com.mytask.backend.repository;

import com.mytask.backend.enums.Importance;
import com.mytask.backend.enums.Priority;
import com.mytask.backend.model.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByPriorityAndImportance(Priority priority, Importance importance);

    List<Task> findByDueDateBetween(LocalDate start, LocalDate end);

    List<Task> findByCheckedFalse();
}