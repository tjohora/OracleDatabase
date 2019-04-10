/* 
TJ O'Hora (D00186562)
Christian Cobalida (D00200161)
Michael Ayesa Momo(D00215808)
Tik Hang Chan (D00128176)
*/


CREATE TABLE hr_jobs
(
	job_id VARCHAR2(10) CONSTRAINT pk_jobs PRIMARY KEY,
	job_title VARCHAR2(35) CONSTRAINT nn_jobs_job_title NOT NULL,
	min_salary NUMBER(6) CONSTRAINT nn_jobs_min_salary NOT NULL,
	max_salary NUMBER(6) CONSTRAINT nn_jobs_max_salary NOT NULL
);

CREATE TABLE hr_departments
(
	department_id NUMBER(4) CONSTRAINT pk_departments PRIMARY KEY,
	department_name VARCHAR2(30) CONSTRAINT nn_department_name NOT NULL CONSTRAINT un_department_name UNIQUE,
	manager_id NUMBER(6)
);

CREATE TABLE hr_employees
(
	employee_id NUMBER(6) 
			CONSTRAINT pk_employees PRIMARY KEY,
	first_name VARCHAR2(20) 
			CONSTRAINT nn_emp_first_name NOT NULL,
	last_name VARCHAR2(25)
			CONSTRAINT nn_emp_last_name NOT NULL,
	email_addr VARCHAR2(25) 
			CONSTRAINT nn_emp_email_addr NOT NULL,
	hire_date DATE DEFAULT TRUNC(SYSDATE)
			CONSTRAINT nn_emp_hire_date NOT NULL 
			CONSTRAINT ck_emp_hire_date CHECK(TRUNC(hire_date) = hire_date),
	country_code VARCHAR2(5) 
			CONSTRAINT nn_emp_country_code NOT NULL,
	phone_number VARCHAR2(20) 
			CONSTRAINT nn_emp_phone_number NOT NULL,
	job_id 
			CONSTRAINT nn_emp_job_id NOT NULL 
			CONSTRAINT fk_emp_jobs REFERENCES hr_jobs,
	job_start_date  DATE 
			CONSTRAINT nn_emp_job_start_date NOT NULL,
			CONSTRAINT ck_emp_job_start_date CHECK(TRUNC(JOB_START_DATE) = job_start_date),
	salary NUMBER(6) 
			CONSTRAINT nn_emp_salary NOT NULL,
	manager_id CONSTRAINT fk_emp_mgr_to_empno REFERENCES hr_employees,
	department_id CONSTRAINT fk_emp_to_dept REFERENCES hr_departments
);

CREATE TABLE hr_job_history
(
	employee_id CONSTRAINT fk_job_hist_to_employees REFERENCES hr_employees,
	job_id CONSTRAINT fk_job_hist_to_jobs REFERENCES hr_jobs,
	start_date DATE CONSTRAINT nn_job_hist_start_date NOT NULL,
	end_date DATE CONSTRAINT nn_job_hist_end_date NOT NULL,
	department_id
            CONSTRAINT fk_job_hist_to_departments REFERENCES hr_departments
            CONSTRAINT nn_job_hist_dept_id NOT NULL,
            CONSTRAINT pk_job_history PRIMARY KEY(employee_id,start_date),
            CONSTRAINT ck_job_history_date CHECK( start_date < end_date )
);


 INSERT INTO hr_jobs (job_id, job_title, min_salary, max_salary) values('11','Doctor',2000,6000);
 INSERT INTO hr_jobs (job_id, job_title, min_salary, max_salary) values('12','Pilot',4000,8000);
 INSERT INTO hr_jobs (job_id, job_title, min_salary, max_salary) values('13','Mechanic',5000,10000);
 INSERT INTO hr_jobs (job_id, job_title, min_salary, max_salary) values('14','Driver',1500,5000);

INSERT INTO hr_departments (department_id, department_name, manager_id) values(2,'Shipping',101);
INSERT INTO hr_departments (department_id, department_name, manager_id) values(3,'Operator',102);
INSERT INTO hr_departments (department_id, department_name, manager_id) values(4,'Secretary',103);
INSERT INTO hr_departments (department_id, department_name, manager_id) values(5,'Welding',104);
INSERT INTO hr_departments (department_id, department_name, manager_id) values(6,'Machinery',105);
INSERT INTO hr_departments (department_id, department_name, manager_id) values(7,'Cashiers',106);
INSERT INTO hr_departments (department_id, department_name, manager_id) values(8,'Accountant',107);
INSERT INTO hr_departments (department_id, department_name, manager_id) values(9,'Quality Control',108);
INSERT INTO hr_departments (department_id, department_name, manager_id) values(10,'Supervisor',109);
<!----------------------------------------------------------------------------------------------------------->
INSERT INTO hr_employees (employee_id,first_name,last_name,email_addr,hire_date,country_code,phone_number,job_id,job_start_date,salary,manager_id,department_id)
 values(1,'Michael','Ayesa','michaelayesa@gmail.com','05/04/2019','+353','025288688',1,'06/04/2019',4000,1,1);

/* Q2.	Create a trigger that will display the employee id, first name,
 last name and job id on screen of all new employees after they are inserted on the hr_employees table. */

CREATE TRIGGER nwemployee_det_trg
AFTER INSERT ON hr_employees 
FOR EACH ROW
WHEN (new.employee_id > 0)
BEGIN
dbms_output.put_line('Employee ID no.' || :new.employee_id);
dbms_output.put_line('Employee Name: ' || :new.first_name || ' ' || :new.last_name);
dbms_output.put_line('Job ID no. : ' || :new.job_id);
END;
/

/*3.	Create a trigger to enforce the following business rule:
“An employee with job j must have a salary between the minimum and maximum salaries for job j”
This rule could be violated either when a new row is inserted into the employees table or when the salary or job_id
column of the employees table is updated. An appropriate error message should be returned if this occurs.
*/

CREATE OR REPLACE TRIGGER minmaxsal_det_trg
AFTER INSERT ON hr_employees
FOR EACH ROW
BEGIN
IF EXISTS(SELECT salary FROM hr_employees HAVING MIN(salary) AND MAX(salary)) THEN
dbms_ouput.new_line;
dbms_output.put_line('Job ID no.' || :new.job_id);
dbms_output.put_line('Job Title: ' || :new.job_title);
dbms_output.put_line('Salary' : || :new.salary);
ELSE
dbms_output.put_line('The salary is not between min and max for employee');
END IF;
EXCEPTION
  WHEN OTHERS THEN
	RAISE_APPLICATION_ERROR (-20001, 'The trigger does not work');
END;
/

/*4. Create a trigger that will display the details on screen of all new departments after they are 
inserted on the hr_departments table. 
*/

CREATE TRIGGER nwdepartments_det_trg
AFTER INSERT ON hr_departments
FOR EACH ROW
WHEN (new.department_id > 0)
BEGIN
dbms_output.new_line;
dbms_output.put_line('Department ID no.' || :new.department_id);
dbms_output.put_line('Department name: ' || :new.department_name);
dbms_output.put_line('Manager ID no.' || :new.manager_id);
END;
/

/*5.Create a trigger to enforce the following business rule:
 “If an employee with job j has salary s, then you cannot change the minimum salary for j to a value 
 greater than s or the maximum salary for j to a value less than s”
 (To do so would make existing data invalid.)
This rule could be violated when the min_salary or max_salary column of the jobs table is updated
*/

CREATE OR REPLACE TRIGGER nwempjobsal_det_trg
AFTER UPDATE OF min_salary ON hr_jobs 
FOR EACH ROW
BEGIN
IF EXISTS(SELECT job_id, job_title FROM hr_jobs, hr_employees WHERE min_salary > salary OR max_salary < salary) THEN
dbms_output.new_line;
dbms_output.put_line('Job ID no. ' || :new.job_id);
dbms_output.put_line('Job start date: ' || :new.job_start_date);
dbms_output.put_line('Salary' : || :new.salary);
ELSE
dbms_output.put_line('The min_salary is greater than salary or max_salary is less than salary');
END IF;
EXCEPTION
  WHEN OTHERS THEN
	RAISE_APPLICATION_ERROR (-20001, 'Error displaying the data');
END;
/

/*6. Create a trigger to fire before the update of job_id on hr_employees so that a row is inserted
 into hr_job_history with employee_id, old job id, old job start date and the system date 
 (for the end date) and old department id. 
*/

CREATE OR REPLACE TRIGGER updjob_det_trg
BEFORE UPDATE OF job_id ON hr_employees
FOR EACH ROW
BEGIN
INSERT INTO hr_job_history
VALUES (employee_id, :old.job_id, :old.start_date, :old.end_date, :old.department_id);
END;
/

/*7.
Load hr_jobs with data from the table HR.JOBS:
*/
INSERT INTO hr_jobs (job_id, job_title, min_salary, max_salary)
SELECT job_id, job_title, min_salary, max_salary
  FROM HR.JOBS
/

/*
Load hr_departments with data from the table HR.DEPARTMENTS:
*/
INSERT INTO hr_departments 
(department_id, 
 department_name, 
 manager_id)
SELECT department_id, department_name, manager_id
  FROM HR.DEPARTMENTS
/

/* Question 8 */
SELECT MAX(department_id)
FROM hr_departments
;

/* Question 9 */
CREATE SEQUENCE DepartmentID_seq
START WITH 3
INCREMENT BY 1
;

/* Question 10 */
SELECT MAX(employee_id)
FROM hr_employees 
;

/* Question 11 */
CREATE SEQUENCE employeeID_seq
START WITH 3
INCREMENT BY 1
;

manager_id CONSTRAINT fk_emp_mgr_to_empno REFERENCES hr_employees,
/* Question 12 */
ALTER TABLE hr_departments
ADD CONSTRAINT fk_emp_mgr_valid
FOREIGN KEY (manager_id)
REFERENCES hr_employees (manager_id)
initially deferred deferrable;

/* Question 13 */
UPDATE hr_employees
SET job_id = "AC_MAGR"
WHERE employee_id = 176
;
/* This does work. */

/* Question 14 */
ALTER TABLE hr_employees 
DROP CONSTRAINT ck_emp_job_start_date
;


/* Question 15 */
INSERT INTO hr_employees 
(employee_id, first_name,last_name, email_addr, hire_date, country_code, phone_number, job_id, job_start_date, salary, manager_id, department_id)
VALUES
(employeeID_seq.nextval, "Yvonne", "Egan","YEGAN",01-APR-2016,"+353","042.970.2222","IT_PROG",sysdate,5000,103,60)
;
/* All the values here are valid, however the salary my cause issues. If the salary is between min_salary and max_salary for IT_PROG, this insert will go through with no issues. However, an error will occur if this rule is violated. */

/* Question 16 */
INSERT INTO hr_employees 
(employee_id, first_name,last_name, email_addr, hire_date, country_code, phone_number, job_id, job_start_date, salary, manager_id, department_id)
VALUES
(employeeID_seq.nextval, "John", "Bergin","JBergin",01-APR-2016’,"+353","046.970.4545","IT_PROG",sysdate,15000,103,60)
;
/* Same as the previous question, but with a new value for salary*/

/* Question 17 */
UPDATE hr_jobs
SET min_salary = 5000
WHERE job_title = "IT_PROG"
;
/* If this new min_salary is less than any of the employees in IT_PROG, a trigger fires preventing this from happening as it violates a rule put in place. */

/* Question 18 */
INSERT INTO hr_departments
(department_id, department_name, manager_id)
VALUE
(DepartmentID_seq.NEXTVAL,"Research",NULL)
;
/* Due to a previously made constraint, this will give an error as manager_id cannot be null. */

 <!--part 3 Q1--->
 SELECT employee_id ,first_name,last_name,salary,
       CASE salary WHEN PU_CLERK THEN salary * 1.07
                   WHEN SH_CLERK THEN salary * 1.08
                   WHEN ST_CLERK THEN salary *1.09
			       WHEN HR_REP THEN salary * 1.05
				   WHEN PR_REP THEN salary * 1.05
				   WHEN MK_REP THEN salary * 1.04
                   ELSE salary *1
       END "New Salary"
FROM hr_employees
ORDER BY employee_id;

<!--Part 3 Q2--->

SELECT job_id ,job_title,max_salary,
   CASE max_salary WHEN PU_CLERK THEN max_salary * 1.02
                   WHEN SH_CLERK THEN max_salary * 1.03
                   WHEN ST_CLERK THEN max_salary *1.05
			       WHEN HR_REP THEN max_salary * 1.04
				   WHEN PR_REP THEN max_salary * 1.04
				   WHEN MK_REP THEN max_salary * 1.01
                   ELSE max_salary *1
       END "Max Salary"
FROM hr_jobs
ORDER BY job_id;

<!--part 3 Q3---->
/*
3.Retrieve the first_name, last_name, country_code, 
job_id and the country (Use the decode function to display ‘UK’ when the country code is +44, 
and ‘USA’ when the country code is +1) for ALL managers only;
******/
  SELECT first_name,last_name,country_code,
       DECODE (country_code, +44, 'UK',
							+1, 'USA',
								'UNKNOWN COUNTY COUDE') 
FROM hr_employees WHERE manager_id = manager_id; 

<!---Q4--->
SELECT first_name,last_name,country_code,job_id,country,
       DECODE (country_code, +44, 'UK',
                          +1, 'USA',
                          'Unknown code') 
FROM hr_departments LEFT OUT JOIN hr_departments ON  hr_departments.department_id = hr_employees.employee_id WHERE hr_departments.department_name = 'reps';
ORDER BY 2;

<!--Part 3 Q5--->
<!--5.Create a stored procedure named add_department to:
/* to the department table.
Test with the following data:
350, Wholesale, 100
-->*/
  CREATE OR REPLACE PROCEDURE add_department 
(
department_id	IN NUMBER,
department_name IN VARCHAR2,
manager_id IN NUMBER
) AS

BEGIN
INSERT INTO hr_departments (
department_id
department_name,
manager_id)
VALUES (
   add_department.department_id,
  add_department.department_name
   add_department.manager_id);
END add_department;
/

--to invoke

CALL add_department (350,'Wholesale',100)

/*Part 3 Question6 -not tested*/
create or replace procedure add_job(
	job_id in varchar2,
	job_title in varchar2,
	min_salary in varchar2,
	max_salary in varchar2
) as
begin
insert into hr_job(	
	job_id,
	job_title,
	min_salary,
	max_salary
)
end add_job;
/

values(
	add_job.job_id,
	add_job.job_title,
	add_job.min_salary,
	add_job.max_salary
	)
/*Part 3 Question7 -not tested*/
create or replace PROCEDURE get_short_term_employees(
	first_name in varchar2,
	last_name in varchar2
)as
cursor cv_employee is
	select first_name, last_name, hire_date
	from hr_employees;
begin
	FOR a IN cv_employee LOOP
		IF a.hire_date < '2009-4-1' THEN
			DBMS_OUTPUT.PUT_LINE(a.first_name || ' ' || a.last_name);
		ELSE	
			DBMS_OUTPUT.PUT_LINE('');
		End IF;
	End LOOP;
EXCEPTION
	WHEN Others then
		DBMS_OUTPUT.PUT_LINE('ERROR: cv_employee');
END;
/

/*Part 3 Question8 -not tested*/
create or replace PROCEDURE get_short_term_employees(
	first_name in varchar2,
	last_name in varchar2
)as
cursor cv_employee_1 is
	select first_name, last_name, hire_date,d.department_id
	from hr_employees,hr_departments d
	where hr_employees.department_id = d.department_id
begin
	FOR a IN cv_employee_1 LOOP
		IF a.hire_date < '1999-4-1' THEN
			DBMS_OUTPUT.PUT_LINE(a.firstname|| ''|| a.last_name|| 'Employed in same job from more than 20 years');
		ELSE	
			DBMS_OUTPUT.PUT_LINE('');
		End IF;
	End LOOP;
EXCEPTION
	WHEN Others then
		DBMS_OUTPUT.PUT_LINE('ERROR: short_term_employees');
END;
/
/*Part 3 Question9 -not tested*/

CREATE OR REPLACE FUNCTION no_of_days_in_job (a_employee_id in number,a_job_id in varchar2)
	return datetime is
	cursor job_history is
		select start_date,end_date 
		from hr_job_history
		where employee_id = a_employee_id
		and job_id =a_job_id;
		mydate datetime;
begin
 FOR job_record IN job_history LOOP
	mydate:= job_record.end_date - job_record.start_date;
   END LOOP;
   /* Debug line */
   DBMS_OUTPUT.PUT_LINE('Total wages = ' || TO_CHAR(mydate)); 
	return mydate;
end no_of_days_in_job;
VARIABLE calculated_date datetime;
EXECUTE :calculated_date := no_of_days_in_job(101,'AC_ACCOUNT');

	
/*Part 3 Question10 -not tested*/
	CREATE OR REPLACE FUNCTION calc_employer_prsi  (emp_id in number) RETURN NUMBER IS
   CURSOR emp_cursor IS
      SELECT employee_id,salary from hr_employees 
	  WHERE employee_id = emp_id;
      total_prsi    NUMBER(11, 2) := 0;
	  prsi CONSTANT NUMBER := .08;
	  
BEGIN

   FOR emp_record IN emp_cursor LOOP
      total_pris := emp_record.salary* prsi;
   END LOOP;
   
   /* Debug line */
   DBMS_OUTPUT.PUT_LINE('Total wages = ' || TO_CHAR(total_pris)); 
   RETURN total_wages;

END calc_employer_prsi;
/

VARIABLE emp_id NUMBER;
EXECUTE :emp_id := calc_employer_prsi(196);
