SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employee;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

--PROJECT TASK
--
Task 1. Create a New Book Record -- "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books(isbn,book_title,category,rental_price,status,author,publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

--Task 2: Update an Existing Member's Address
UPDATE members
SET member_address='125 Main st'
WHERE member_id='C101'

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id='IS121';

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id='E101';

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book
SELECT member_id,member_name,COUNT(issued_member_id ) as total_book_issued
FROM issued_status
INNER JOIN members
ON members.member_id=issued_status.issued_member_id
GROUP BY member_name,member_id
HAVING COUNT(issued_member_id )>1;

--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE books_counts
AS
SELECT isbn,book_title,COUNT(issued_book_isbn) as total_book_issued
FROM issued_status
INNER JOIN books
ON books.isbn=issued_status.issued_book_isbn
GROUP BY isbn,book_title;

--Task 7. Retrieve All Books in a Specific Category:
SELECT * FROM books
WHERE category='Fantasy';

--Task 8: Find Total Rental Income by Category:
SELECT category,SUM(rental_price) AS total_income
FROM books
GROUP BY category;

--Task 9: List Members Who Registered in the Last 720 Days:
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '720 days';

--TASK 10: List Employees with Their Branch Manager's Name and their branch detaiSELECT 
SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employee as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id    
JOIN
employee as e2
ON e2.emp_id = b.manager_id;

-- TASK 11: Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE above_threshold
AS
SELECT * FROM books
WHERE rental_price>(SELECT AVG(rental_price) FROM books);

--Task 12: Retrieve the List of Books Not Yet Returned
SELECT * 
FROM issued_status
LEFT JOIN return_status
ON issued_status.issued_id=return_status.issued_id
WHERE return_book_isbn IS NULL;

--Task 13: Identify Members with Overdue Books
SELECT issued_member_id, member_name,book_title ,issued_date,
CURRENT_DATE-issued_date AS overdue_days
FROM issued_status
INNER JOIN members
ON members.member_id=issued_status.issued_member_id
INNER JOIN books
ON books.isbn=issued_status.issued_book_isbn
LEFT JOIN return_status 
ON return_status.issued_id = issued_status.issued_id
WHERE return_status.issued_id IS NULL
AND(CURRENT_DATE - issued_status.issued_date) > 30
GROUP BY issued_member_id, member_name,book_title ,issued_date

--Task 14: Update Book Status on Return

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

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

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$


-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');

-- calling function 
CALL add_return_records('RS148', 'IS140', 'Good');

--Task 15: Branch Performance Report
CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
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

SELECT * FROM branch_reports;

