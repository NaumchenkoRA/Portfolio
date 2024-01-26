-- Первая часть проекта --

/* 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки». */

SELECT COUNT(p.id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id
WHERE pt.type = 'Question' AND (score > 300 OR favorites_count >= 100)

/* 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа. */

SELECT ROUND(AVG(kolvo))
FROM
    (SELECT p.creation_date::date AS date,
           COUNT(p.id) AS kolvo
    FROM stackoverflow.posts AS p
    JOIN stackoverflow.post_types AS pt ON p.post_type_id = pt.id
    WHERE pt.type = 'Question' AND p.creation_date::date BETWEEN '2008-11-01' AND '2008-11-18'
    GROUP BY date) AS table1
      
/* 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей. */

SELECT COUNT(DISTINCT user_id)
FROM stackoverflow.users u
JOIN stackoverflow.badges b ON u.id = b.user_id
WHERE b.creation_date::date = u.creation_date::date

/* 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос? */

SELECT COUNT(table1.id)
FROM (SELECT p.id
      FROM stackoverflow.posts p
      JOIN stackoverflow.votes v ON p.id=v.post_id
      JOIN stackoverflow.users u ON p.user_id=u.id
      WHERE u.display_name LIKE 'Joel Coehoorn' AND v.id > 0
      GROUP BY p.id) AS table1

/* 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. 
Таблица должна быть отсортирована по полю id. */

SELECT *,
       ROW_NUMBER() OVER(ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id

/* 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя. */

SELECT u.id AS user_id,
       COUNT(v.id) AS votes_cnt
FROM stackoverflow.users u
JOIN stackoverflow.votes v ON u.id = v.user_id
JOIN stackoverflow.vote_types vt ON v.vote_type_id = vt.id
WHERE vt.name = 'Close'
GROUP BY u.id
ORDER BY votes_cnt DESC, user_id DESC
LIMIT 10
      
/* 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей: идентификатор пользователя, число значков, место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя. */

SELECT *,
       DENSE_RANK() OVER (ORDER BY kolvo DESC) AS rating
FROM (SELECT user_id,
             COUNT(id) AS kolvo
      FROM stackoverflow.badges
      WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15' 
      GROUP BY user_id
      ORDER BY kolvo DESC, user_id 
      LIMIT 10) AS table1;

/* 8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей: заголовок поста, идентификатор пользователя, число очков поста.
Cреднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков. */

SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title != '' AND score != 0

/* 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
Посты без заголовков не должны попасть в список. */

SELECT title
FROM stackoverflow.posts p
WHERE user_id IN
    (SELECT user_id
    FROM stackoverflow.badges
    GROUP BY user_id
    HAVING COUNT(id) > 1000)
AND title IS NOT NULL

/* 10. Напишите запрос, который выгрузит данные о пользователях из США (англ. United States).
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу. */

SELECT id,
       views,
       CASE
          WHEN views >= 350 THEN 1
          WHEN views < 100 THEN 3
          ELSE 2
       END AS group_prosmotr
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views > 0


/* 11. Дополните предыдущий запрос. 
Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора. */

WITH table1 AS (SELECT id,
       views,
       CASE
          WHEN views >= 350 THEN 1
          WHEN views < 100 THEN 3
          ELSE 2
       END AS group_prosmotr
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views > 0)

SELECT id,
       group_prosmotr,
       views
FROM 
     
    (SELECT *,
           MAX(views) OVER (PARTITION BY group_prosmotr ORDER BY views DESC) AS max_views
    FROM table1) AS max_v
WHERE views = max_views
ORDER BY views DESC, id

/* 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. 
Сформируйте таблицу с полями: номер дня, число пользователей, зарегистрированных в этот день, сумму пользователей с накоплением. */

SELECT *,
     SUM(count_ppl) OVER (ORDER BY days)
FROM (SELECT EXTRACT(DAY FROM creation_date::date) AS days,
             COUNT(id) AS count_ppl
      FROM stackoverflow.users
      WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
      GROUP BY days) AS table1;


/* 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. 
Отобразите: идентификатор пользователя, разницу во времени между регистрацией и первым постом. */

SELECT DISTINCT(p.user_id),
       MIN(p.creation_date) OVER (PARTITION BY p.user_id) - u.creation_date AS raznica
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON p.user_id = u.id


-- Вторая часть проекта --


/* 1. Выведите общую сумму просмотров постов за каждый месяц 2008 года. 
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
Результат отсортируйте по убыванию общего количества просмотров. */

SELECT DATE_TRUNC('month', creation_date)::date AS month,
       SUM(views_count) 
FROM stackoverflow.posts
GROUP BY month
ORDER BY SUM(views_count) DESC

/* 2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. 
Вопросы, которые задавали пользователи, не учитывайте. 
Для каждого имени пользователя выведите количество уникальных значений user_id. 
Отсортируйте результат по полю с именами в лексикографическом порядке. */

SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON p.user_id=u.id
JOIN stackoverflow.post_types pt ON pt.id=p.post_type_id
WHERE p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month') 
      AND pt.type LIKE '%Answer%'
GROUP BY u.display_name
HAVING COUNT(DISTINCT p.id) > 100

/* 3. Выведите количество постов за 2008 год по месяцам. 
Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. 
Отсортируйте таблицу по значению месяца по убыванию. */

SELECT DATE_TRUNC('month', creation_date)::date AS month,
       COUNT(DISTINCT id) AS count
FROM stackoverflow.posts
WHERE user_id IN (
    SELECT DISTINCT u.id
    FROM stackoverflow.users u
    JOIN stackoverflow.posts p ON u.id = p.user_id
    WHERE u.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30'
    AND p.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31'
    )
AND EXTRACT(YEAR FROM creation_date) = 2008
GROUP BY month
ORDER BY month DESC
      
/* 4. Используя данные о постах, выведите несколько полей:
- идентификатор пользователя, который написал пост;
- дата создания поста;
- количество просмотров у текущего поста;
- сумму просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста. */

SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts

/* 5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
Нужно получить одно целое число — не забудьте округлить результат. */

SELECT ROUND(AVG(skoka_dney))
FROM 
    (SELECT user_id,
           COUNT(DISTINCT creation_date::date) skoka_dney
    FROM stackoverflow.posts
    WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
    GROUP BY user_id) AS table1

/* 6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? 
Отобразите таблицу со следующими полями:
- номер месяца;
- количество постов за месяц;
- процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. 
Округлите значение процента до двух знаков после запятой. */

WITH table1 AS (
    SELECT EXTRACT(MONTH from creation_date::date) AS month,
           COUNT(DISTINCT id)    
    FROM stackoverflow.posts
    WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
    GROUP BY month)

SELECT *,
       ROUND(((count::numeric / LAG(count) OVER (ORDER BY month)) - 1) * 100, 2)
FROM table1
      
/* 7.Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время.
Выведите данные за октябрь 2008 года в таком виде:
- номер недели;
- дата и время последнего поста, опубликованного на этой неделе. */

WITH table1 AS (
    SELECT user_id,
           COUNT(DISTINCT id) AS count
    FROM stackoverflow.posts
    GROUP BY user_id
    ORDER BY count DESC
    LIMIT 1),

     table2 AS (
    SELECT p.user_id,
           p.creation_date,
           extract('week' from p.creation_date) AS week
    FROM stackoverflow.posts AS p
    JOIN table1 ON table1.user_id = p.user_id
    WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01')

SELECT DISTINCT week::numeric,
       MAX(creation_date) OVER (PARTITION BY week)
FROM table2
ORDER BY week;

