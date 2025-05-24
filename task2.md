# Task 2 — Оптимизация запроса без изменения схемы БД

---

## Промпт на оптимизацию

**Модель:** OpenAI o3

```text
Предложи правки запроса SELECT TOP (3000) * FROM dbo.F_WORKS_LIST();без модификации структуры БД такие,  
чтобы время получения 3 000 заказов из 50 000 (≈ 3 позиции в заказе) не превышало 1–2 сек.
```

## Ответ модели и реализованные правки

LLM посоветовала:

1. **Переписать `F_WORKS_LIST` в inline TVF** (убрать табличную переменную).
2. **Заменить скалярные `F_WORKITEMS_COUNT_BY_ID_WORK` на агрегаты `OUTER APPLY COUNT(*)`**.
3. **Добавить два покрывающих индекса:**
   * `(Id_Work, Is_Complit) INCLUDE(Price)` на `WorkItem`;
   * `(CREATE_Date DESC, Id_Employee)` на `Works`.


## Итоговые скрипты

* **`Rewrite_F_WORKS_LIST.sql`** — inline-TVF без RBAR.
* **`Create_Index_WorkItem.sql`** — `IX_WorkItem_IdWork_IsComplit`.
* **`Create_Index_Works.sql`** — `IX_Works_CreateDate_Employee`.


## Замеры производительности

### До оптимизации

```
SQL Server Execution Times:
   CPU time = 14992 ms,  elapsed time = 14913 ms.
Total execution time: 00:00:14.926
```

### После оптимизации

```
SQL Server Execution Times:
   CPU time = 32 ms,  elapsed time = 32 ms.
Total execution time: 00:00:00.045
```

**Логические чтения** `WorkItem`: 34 → 12 821 (один сет-скан вместо 6 000 seek-циклов).

---

## Результат

* Время ответа сократилось с **≈ 15 с** до **≈ 0,03 с** (> 450× быстрее).
* Цель «≤ 2 сек» выполнена с огромным запасом.
* Все изменения достигнуты **без изменения структуры БД** — только переписка кода и два индекса.

