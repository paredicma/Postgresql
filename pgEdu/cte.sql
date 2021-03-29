--CTE

WITH users_tasks AS (
  SELECT 
         users.email,
         array_agg(tasks.name) as task_list,
         projects.title
  FROM
       users,
       tasks,
       project
  WHERE
        users.id = tasks.user_id
        projects.title = tasks.project_id
  GROUP BY
           users.email,
           projects.title
)

SELECT *
FROM users_tasks;

------------------------
total_tasks_per_project AS (
  SELECT 
         project_id,
         count(*) as task_count
  FROM tasks
  GROUP BY project_id
),

tasks_per_project_per_user AS (
  SELECT 
         user_id,
         project_id,
         count(*) as task_count
  FROM tasks
  GROUP BY user_id, project_id
),

overloaded_users AS (
  SELECT tasks_per_project_per_user.user_id,

  FROM tasks_per_project_per_user,
       total_tasks_per_project
  WHERE tasks_per_project_per_user.task_count > (total_tasks_per_project / 2)
)

------------------------


WITH users_tasks AS (
  SELECT 
         users.id as user_id,
         users.email,
         array_agg(tasks.name) as task_list,
         projects.title
  FROM
       users,
       tasks,
       project
  WHERE
        users.id = tasks.user_id
        projects.title = tasks.project_id
  GROUP BY
           users.email,
           projects.title
),

--- Calculates the total tasks per each project
total_tasks_per_project AS (
  SELECT 
         project_id,
         count(*) as task_count
  FROM tasks
  GROUP BY project_id
),

--- Calculates the projects per each user
tasks_per_project_per_user AS (
  SELECT 
         user_id,
         project_id,
         count(*) as task_count
  FROM tasks
  GROUP BY user_id, project_id
),

--- Gets user ids that have over 50% of tasks assigned
overloaded_users AS (
  SELECT tasks_per_project_per_user.user_id,

  FROM tasks_per_project_per_user,
       total_tasks_per_project
  WHERE tasks_per_project_per_user.task_count > (total_tasks_per_project / 2)
)

SELECT 
       email,
       task_list,
       title
FROM 
     users_tasks,
     overloaded_users
WHERE
      users_tasks.user_id = overloaded_users.user_id;
