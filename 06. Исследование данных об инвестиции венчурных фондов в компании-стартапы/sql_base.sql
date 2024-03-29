/* Задание 1. Посчитайте, сколько компаний закрылось. */

SELECT COUNT(status)
FROM company
WHERE status = 'closed';

/* Задание 2. Отобразите количество привлечённых средств для новостных компаний США. 
Используйте данные из таблицы company. Отсортируйте таблицу по убыванию значений в поле funding_total. */

SELECT funding_total
FROM company
WHERE category_code = 'news' AND country_code = 'USA'
ORDER BY funding_total DESC;

/* Задание 3. Найдите общую сумму сделок по покупке одних компаний другими в долларах. 
Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно. */

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash' AND
      EXTRACT(YEAR FROM acquired_at) BETWEEN 2011 AND 2013;

/* Задание 4. Отобразите имя, фамилию и названия аккаунтов людей в твиттере, у которых названия аккаунтов начинаются на 'Silver'. */

SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%';

/* Задание 5. Выведите на экран всю информацию о людях, у которых названия аккаунтов в твиттере содержат подстроку 'money', а фамилия начинается на 'K'. */

SELECT *
FROM people
WHERE twitter_username LIKE '%money%' 
      AND last_name LIKE 'K%';

/* Задание 6. Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране.
Страну, в которой зарегистрирована компания, можно определить по коду страны. Отсортируйте данные по убыванию суммы. */ 

SELECT country_code, SUM(funding_total)
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC;

/* Задание 7. Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению. */

SELECT funded_at,
       MIN(raised_amount),
       MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) != 0 AND MIN(raised_amount) !=  MAX(raised_amount)

/* Задание 8. Создайте поле с категориями:
Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию high_activity.
Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию middle_activity.
Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию low_activity.
Отобразите все поля таблицы fund и новое поле с категориями. */

SELECT *,
      CASE
           WHEN invested_companies >= 100 THEN 'high_activity'
           WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
           ELSE 'low_activity'
      END
FROM fund

/* Задание 9. Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие.
Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего. */

SELECT
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND(AVG(investment_rounds)) AS avg
FROM fund
GROUP BY activity
ORDER BY avg 

/* Задание 10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно.
Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. Выгрузите десять самых активных стран-инвесторов.
Отсортируйте таблицу по среднему количеству компаний от большего к меньшему, а затем по коду страны в лексикографическом порядке. */

SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) BETWEEN '2010' AND '2012'
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY AVG(invested_companies) DESC, country_code
LIMIT 10 ;

/* Задание 11. Отобразите имя и фамилию всех сотрудников стартапов. 
Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна. */ 

SELECT ppl.first_name,
       ppl.last_name,
       ed.instituition
FROM people AS ppl
LEFT JOIN education AS ed ON ppl.id = ed.person_id

/* Задание 12. Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. 
Выведите название компании и число уникальных названий учебных заведений. Составьте топ-5 компаний по количеству университетов. */

SELECT c.name,
       COUNT(DISTINCT ed.instituition) 
FROM company AS c
INNER JOIN people AS ppl ON c.id = ppl.company_id
INNER JOIN education AS ed ON ppl.id = ed.person_id
GROUP BY c.name
ORDER BY COUNT(DISTINCT ed.instituition) DESC
LIMIT 5

/* Задание 13. Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним. */

SELECT DISTINCT c.name
FROM company AS c
LEFT OUTER JOIN funding_round AS fr ON c.id = fr.company_id
WHERE status = 'closed'
AND is_first_round = 1
AND is_last_round = 1


/* Задание 14. Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании. */

SELECT DISTINCT p.id
FROM people AS p

WHERE p.company_id IN
(SELECT DISTINCT c.id
FROM company AS c
LEFT OUTER JOIN funding_round AS fr ON c.id = fr.company_id
WHERE status = 'closed'
AND is_first_round = 1
AND is_last_round = 1)


/* Задание 15. Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник. */

SELECT DISTINCT ppl.id AS idp, 
       ed.instituition AS edi
FROM people AS ppl
LEFT OUTER JOIN education AS ed ON ppl.id = ed.person_id
WHERE ppl.id IN (SELECT DISTINCT p.id AS idp
                 FROM people AS p
                 WHERE p.company_id IN
                 (SELECT DISTINCT c.id
                  FROM company AS c
                   LEFT OUTER JOIN funding_round AS fr ON c.id = fr.company_id
                   WHERE status = 'closed'
                  AND is_first_round = 1
                    AND is_last_round = 1))
AND ed.instituition IS NOT NULL


/* Задание 16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды. */

SELECT DISTINCT ppl.id AS idp, 
       COUNT(ed.instituition) AS edi
FROM people AS ppl
LEFT OUTER JOIN education AS ed ON ppl.id = ed.person_id
WHERE ppl.id IN (SELECT DISTINCT p.id AS idp
                 FROM people AS p
                 WHERE p.company_id IN
                (SELECT DISTINCT c.id
                 FROM company AS c
                 LEFT OUTER JOIN funding_round AS fr ON c.id = fr.company_id
                 WHERE status = 'closed'
                 AND is_first_round = 1
                 AND is_last_round = 1))
AND ed.instituition IS NOT NULL
GROUP BY idp

/* Задание 17. Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники разных компаний.
Нужно вывести только одну запись, группировка здесь не понадобится. */

SELECT AVG(table1.edi)
FROM 
(SELECT DISTINCT ppl.id AS idp, 
       COUNT(ed.instituition) AS edi
FROM people AS ppl
LEFT OUTER JOIN education AS ed ON ppl.id = ed.person_id
WHERE ppl.id IN (SELECT DISTINCT p.id AS idp
                 FROM people AS p
                 WHERE p.company_id IN
                (SELECT DISTINCT c.id
                 FROM company AS c
                 LEFT OUTER JOIN funding_round AS fr ON c.id = fr.company_id
                 WHERE status = 'closed'
                 AND is_first_round = 1
                 AND is_last_round = 1))
AND ed.instituition IS NOT NULL
GROUP BY idp) AS table1

/* Задание 18. Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook (сервис, запрещённый на территории РФ). */

SELECT AVG(table1.edi)
FROM 
(SELECT DISTINCT ppl.id AS idp, 
        COUNT(ed.instituition) AS edi
FROM company AS c
LEFT OUTER JOIN people AS ppl ON c.id = ppl.company_id
LEFT OUTER JOIN education AS ed ON ppl.id = ed.person_id
WHERE c.name = 'Facebook' 
AND ed.instituition IS NOT NULL
GROUP BY idp) AS table1


/* Задание 19. Составьте таблицу из полей: 
name_of_fund — название фонда;
name_of_company — название компании;
amount — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно. */

SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i
INNER JOIN company AS c ON i.company_id = c.id
INNER JOIN fund AS f ON i.fund_id=f.id
INNER JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE c.milestones > 6
AND EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2012 AND 2013


/* Задание 20. Выгрузите таблицу, в которой будут такие поля:
название компании-покупателя;
сумма сделки;
название компании, которую купили;
сумма инвестиций, вложенных в купленную компанию;
доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.

Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы.
Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. Ограничьте таблицу первыми десятью записями. */

WITH
table1 AS (
SELECT 
       c.name AS pokupatel, 
       acq.price_amount AS summa_sdelki,
       acq.id AS svyaz      
FROM acquisition AS acq
LEFT JOIN company AS c ON acq.acquiring_company_id = c.id
WHERE acq.price_amount > 0
),
table2 AS (
SELECT 
       c.name AS kogo_kupili, 
       c.funding_total AS invest_total,
       acq.id AS svyaz      
FROM acquisition AS acq
LEFT JOIN company AS c ON acq.acquired_company_id = c.id
WHERE c.funding_total > 0
) 
SELECT table1.pokupatel,
       table1.summa_sdelki,
       table2.kogo_kupili,
       table2.invest_total,
       ROUND(table1.summa_sdelki / table2.invest_total) AS dolya
      
FROM table1 
JOIN table2 ON table1.svyaz = table2.svyaz
ORDER BY summa_sdelki DESC, kogo_kupili
LIMIT 10


/* Задание 21. Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. 
Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования. */

SELECT c.name,
       EXTRACT(MONTH FROM CAST(funded_at AS date)) AS month
FROM company AS c
LEFT JOIN funding_round AS fr ON c.id = fr.company_id
WHERE category_code = 'social'
AND EXTRACT(YEAR FROM CAST(funded_at AS date)) BETWEEN 2010 AND 2013
AND fr.raised_amount != 0

/* Задание 22. Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды.
Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля: 
номер месяца, в котором проходили раунды;
количество уникальных названий фондов из США, которые инвестировали в этом месяце;
количество компаний, купленных за этот месяц;
общая сумма сделок по покупкам в этом месяце. */

WITH 
table1 AS (
SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS date)) AS month,
       COUNT(DISTINCT f.name) AS kolvo
FROM fund AS f
LEFT JOIN investment AS inv ON f.id = inv.fund_id
LEFT JOIN funding_round AS fr ON inv. funding_round_id= fr.id
WHERE EXTRACT(YEAR FROM CAST(fr.funded_at AS date)) BETWEEN 2010 AND 2013
      AND f.country_code = 'USA'
GROUP BY month),
table2 AS (
SELECT EXTRACT(MONTH FROM CAST(acquired_at AS date)) AS month,
       COUNT(acquired_company_id) AS kuplennuh,
       SUM(price_amount) AS total
FROM acquisition
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN 2010 AND 2013
GROUP BY month
ORDER BY month)

SELECT table1.month,
       table1.kolvo,
       table2.kuplennuh,
       table2.total
FROM table1 
JOIN table2 ON table1.month = table2.month

/* Задание 23. Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. 
Данные за каждый год должны быть в отдельном поле. 
Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему. */

WITH
table1 AS
(SELECT country_code,
       AVG(funding_total) AS avg2011
FROM company
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2011
GROUP BY country_code),
table2 AS
(SELECT country_code,
       AVG(funding_total) AS avg2012
FROM company
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2012
GROUP BY country_code),
table3 AS
(SELECT country_code,
       AVG(funding_total) AS avg2013
FROM company
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2013
GROUP BY country_code)

SELECT table1.country_code,
       table1.avg2011,
       table2.avg2012,
       table3.avg2013
FROM table1 
INNER JOIN table2 ON table1.country_code = table2.country_code
INNER JOIN table3 ON table1.country_code = table3.country_code
ORDER BY avg2011 DESC
