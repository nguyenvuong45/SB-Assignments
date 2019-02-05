/* Welcome to the SQL mini project. For this project, you will use
Springboard' online SQL platform, which you can log into through the
following link:

https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

Note that, if you need to, you can also download these tables locally.

In the mini project, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */



/* Q1: Some of the facilities charge a fee to members, but some do not.
Please list the names of the facilities that do. */

-- Filtering out facilities with cost of 0 for members: Squash, both Tennis courts, and both massage rooms are not free
SELECT *                              
FROM country_club.Facilities
WHERE membercost !=0


/* Q2: How many facilities do not charge a fee to members? */


-- Aggregate count of free facilities
SELECT COUNT( 1 ) 
FROM country_club.Facilities
WHERE membercost =0
-- 4 facilities free to members


/* Q3: How can you produce a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost?
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */


-- Conditional WHERE to filter fees of < 20% of monthly fee. 
SELECT facid,
       name,
       membercost,
       monthlymaintenance
FROM country_club.Facilities
WHERE membercost != 0
AND membercost < (monthlymaintenance * .2)
--All facilities which are not free to member cost less than 20% of mentainance fee.


/* Q4: How can you retrieve the details of facilities with ID 1 and 5?
Write the query without using the OR operator. */


-- Use IN operator with list of 1 and 5 instead of OR
SELECT * 
FROM country_club.Facilities
WHERE facid IN (1,5)



/* Q5: How can you produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100? Return the name and monthly maintenance of the facilities
in question. */


-- Using CASE for conditional
SELECT name,
       monthlymaintenance,
       CASE WHEN monthlymaintenance < 100 THEN 'cheap'
       ELSE 'expensive' END AS label
FROM country_club.Facilities



/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Do not use the LIMIT clause for your solution. */


-- Using self join of Members table to grab details of member with max join date which is the lastest member
SELECT firstname,
       surname,
       joindate
FROM country_club.Members t1
JOIN (SELECT max(t2.joindate) latest              --self join
      FROM country_club.Members t2
     ) t3 ON t3.latest = t1.joindate              --filter to grab only lastest date
-- Darren Smith who joined on 2012-09-26 at 18:08:45 is the lastest member to join




/* Q7: How can you produce a list of all members who have used a tennis court?
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */



SELECT DISTINCT CONCAT( f.name,  ' ', m.firstname,  ' ', m.surname )         --Unique concatenated values 
FROM country_club.Bookings b
JOIN country_club.Facilities f ON b.facid = f.facid                          --Joining Bookings with Facilities
AND f.name LIKE  'Tennis%'                                                   --Additional condition to filter only tennis
JOIN country_club.Members m ON m.memid = b.memid                             --Third join for members info




/* Q8: How can you produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30? Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT 
CASE WHEN b.memid =0                                        --Conditional for formatting to not reapeat guest in row
THEN CONCAT( f.name,  ' ', m.firstname )                    --Only concat one GUEST to string
ELSE CONCAT( f.name,  ' ', m.firstname,  ' ', m.surname )   --Otherwise concat member's first and last name
END AS booking_info, 
CASE WHEN b.memid !=0                                       --Conditional for filtering and calculating cost accordingly
AND f.membercost * b.slots >30                              
THEN f.membercost * b.slots
WHEN b.memid =0
AND f.guestcost * b.slots >30
THEN f.guestcost * b.slots
ELSE NULL 
END AS cost
FROM country_club.Bookings b                                --Double joining for all necessary info
JOIN country_club.Facilities f ON b.facid = f.facid
JOIN country_club.Members m ON m.memid = b.memid
WHERE (b.starttime BETWEEN  '2012-09-14' AND  '2012-09-15') --Filtering out costs of less than $30
AND (
(b.memid !=0 AND f.membercost * b.slots >30)
OR (b.memid =0 AND f.guestcost * b.slots >30)
    )
ORDER BY cost DESC 




/* Q9: This time, produce the same result as in Q8, but using a subquery. */




SELECT * 
FROM (
    SELECT 
    CASE WHEN b.memid =0
    THEN CONCAT( f.name,  ' ', m.firstname ) 
    ELSE CONCAT( f.name,  ' ', m.firstname,  ' ', m.surname ) 
    END AS booking_info, 
    CASE WHEN b.memid !=0
    AND f.membercost * b.slots >30
    THEN f.membercost * b.slots                                 --Subquery: similar to #8 but creating table first then filter out null
    WHEN b.memid =0
    AND f.guestcost * b.slots >30
    THEN f.guestcost * b.slots
    ELSE NULL END AS cost
    FROM country_club.Bookings b
    JOIN country_club.Facilities f ON b.facid = f.facid
    JOIN country_club.Members m ON m.memid = b.memid
    WHERE (b.starttime BETWEEN  '2012-09-14' AND  '2012-09-15')
    ) subq
WHERE subq.cost IS NOT NULL
ORDER BY cost DESC




/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */



SELECT SUM(calc.cost) AS total_revenue,
       calc.name
FROM (
SELECT f.name, f.facid,                                   --Selecting only necessary columns for subquery
    CASE WHEN b.memid = 0 THEN b.slots * f.guestcost      --Conditional to calculate cost according to GUEST and member price
    ELSE b.slots * f.membercost END AS cost               
FROM country_club.Bookings b                             
JOIN country_club.Facilities f ON b.facid = f.facid       --Only need info from Members and Facilities tables
    ) calc
GROUP BY calc.facid                                       --Aggregate by facility
HAVING sum(calc.cost) < 1000                              --Filter with HAVING 
ORDER BY total_revenue

