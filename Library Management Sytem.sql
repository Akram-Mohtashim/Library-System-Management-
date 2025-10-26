-----Project Task-----
------------------CRUD OPERATIONS-----------------
-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO BOOKS VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')
SELECT * FROM books;


--Task 2: Update an Existing Member's Address

UPDATE members
SET member_address ='125 Oak St'
WHERE member_id = 'C103'



--Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS121'


--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101'


--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_emp_id,
		COUNT(*)
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1


---------- CTAS (Create Table As Select)-------------------

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_counts
AS
Select 
	b.isbn,
	b.book_title,
	COUNT(ist.issued_id) as no_issued
FROM books as b
JOIN
issued_status as ist
ON ist.Issued_book_isbn = b.isbn
GROUP BY 1, 2;


Select * FROM book_counts; 




------------------Data Analysis & Findings-------------------------

----Task 7. Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'Fiction';



----Task 8: Find Total Rental Income by Category:

Select category,
		SUM(rental_price) as Total_rentalIncome
From books
GROUP BY 1




----Task 9.List Members Who Registered in the Last 4 years:

SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '4 years'




---Task 10.List Employees with Their Branch Manager's Name and their branch details:


SELECT 
	 	e1.emp_id,
	    e1.emp_name,
	    e1.position,
	    e1.salary,
	    b.*,
	    e2.emp_name as manager
FROM employees as e1
JOIN branch as b
ON e1.branch_id = b.branch_id
JOIN employees as e2
on e2.emp_id= b.manager_id


---Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:

CREATE TABLE expensive_books AS
SELECT * 
FROM books
WHERE rental_price > 7


---Task 12: Retrieve the List of Books Not Yet Returned

SELECT * FROM issued_status as ist
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL



/*Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, 
member's name, book title, issue date, and days overdue.*/

---Issued_status == members == books == return_status
---Filter book which is return
---Overdue > 30 days

SELECT 
		ist.issued_member_id,
		m.member_name,
		bk.book_title,
		ist.issued_date,
		--rs.return_date,
		CURRENT_DATE - ist.issued_date as Over_Dues
FROM issued_status as ist
JOIN 
members as m
ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
	rs.return_date IS NULL
	AND (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1	



/*Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes"
when they are returned (based on entries in the return_status table).*/


---Manaually

SELECT *
FROM books
WHERE ISBN = '978-0-451-52994-2'


UPDATE books
SET status = 'no'
WHERE isbn = '978-0-451-52994-2'


SELECT *
FROM return_status
WHERE issued_id = 'IS130'

INSERT INTO return_status (return_id, issued_id, return_date)
VALUES
	('RS126', 'IS130', CURRENT_DATE)


UPDATE books
SET status = 'yes'
WHERE isbn = '978-0-451-52994-2'

SELECT *
FROM books
WHERE ISBN = '978-0-451-52994-2'


---STORE PROCEDURE

CREATE OR REPLACE PROCEDURE add_return_record(p_return_id  VARCHAR(20), p_issued_id VARCHAR(40))
LANGUAGE plpgsql
AS $$

DECLARE 
	v_isbn VARCHAR(20);
	v_book_name VARCHAR(75);
BEGIN 
	-- all logic and code
	-- Inserting into return based on user input
		INSERT INTO return_status (return_id, issued_id, return_date )
		VALUES
		(p_return_id, p_issued_id,CURRENT_DATE);

		SELECT 
			issued_book_isbn,
			issued_book_name
			INTO
			v_isbn,
			v_book_name
		FROM issued_status
		WHERE issued_id = p_issued_id;
		
		UPDATE books
		SET status = 'yes'
		WHERE isbn = v_isbn;

		RAISE NOTICE 'Thank you for returing the book: %', v_book_name;
END;
$$


---Calling Function
CALL add_return_record ('RS135', 'IS135');

---Testing Function

SELECT *
FROM issued_status
WHERE issued_id ='IS135'


SELECT *
FROM return_status
WHERE issued_id ='IS135'

SELECT *
FROM books
WHERE ISBN = '978-0-307-58837-1'

/*Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, 
the number of books returned, and the total revenue generated from book rentals.*/


CREATE TABLE branch_report
AS
SELECT 
		b.branch_id,
		b.manager_id,
		COUNT(ist.issued_id) as No_of_Books,
		COUNT (rs.return_id) as No_of_return,
		Sum(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;


SELECT *
FROM branch_report



/*ask 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members 
containing members who have issued at least one book in the last 2 years.*/


CREATE TABLE active_members
AS

SELECT * FROM members
WHERE member_id IN
(
SELECT 
		DISTINCT issued_member_id
FROM issued_status
WHERE 
		issued_date > CURRENT_DATE - INTERVAL '2 year'
)



SELECT * FROM active_members





/*Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.*/


SELECT 
		e.emp_name,
		b.*,
		COUNT(ist.issued_id) as no_of_book
		
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON b.branch_id = e.branch_id
GROUP BY 1,2
ORDER BY no_of_book DESC
LIMIT 3



/*Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.*/


SELECT *
FROM books


SELECT *
FROM issued_status


CREATE OR REPLACE PROCEDURE issue_book (p_issued_id VARCHAR(20), p_issued_member_id VARCHAR(40), p_issued_book_isbn VARCHAR(40), p_issued_emp_id VARCHAR(40))
LANGUAGE plpgsql
AS $$

DECLARE
-- all the variable
		v_status VARCHAR(15);
BEGIN
-- all the logic
	--- checking if book is available 'yes'
	SELECT 
		Status
		INTO
		v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;

	IF v_status = 'yes' THEN
		
		INSERT INTO issued_status(issued_id, issued_member_id,issued_date, issued_book_isbn, issued_emp_id)
				VALUES
					(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

					UPDATE books
					SET status = 'no'
					WHERE isbn = p_issued_book_isbn;

				RAISE NOTICE 'Book record added successfully for book ISBN : %', p_issued_book_isbn;
	ELSE
		
		RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
	END IF;
	
END;
$$


CALL issue_book('IS162', 'C105', '978-0-393-91257-8', 'E110' )


978-0-393-91257-8 -- yes
978-0-7432-7357-1  -- no





/*Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.*/

CREATE TABLE book_overdue
AS

SELECT
		bk.isbn,
		bk.book_title, 
		ist.issued_date,
		CASE WHEN AGE (CURRENT_DATE , issued_date) > INTERVAL '30 days'
			 THEN (EXTRACT(DAY FROM AGE(CURRENT_DATE, issued_date) - INTERVAL '30 days'/8600) * 10)
			 ELSE 0
			 END as Fine
FROM books as bk
JOIN
issued_status as ist
ON ist.issued_book_isbn = bk.isbn
LEFT JOIN
return_status rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL


SELECT *
FROM book_overdue


