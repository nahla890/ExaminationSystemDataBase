use ExaminationSystemDB;


-- ============================================
-- All Views
-- ============================================
go
-- 1
create view Person.View_StudentInfo as
select s.StdID, u.Name as StudentName, u.Email, u.Phone,
       C.ID, b.Name as BranchName, t.Name as TrackName
from Person.Student s
	join Person.[User] u on s.StdID = u.UserID
	join ITI.Class C on s.ClassID = C.ID
	join ITI.Branch b on C.BranchID = b.BranchID
	join ITI.Track t on C.TrackID = t.TrackID
	
go
--2
create view Person.View_StudentExams as
select 
	SE.StudID, E.ExamID, E.ExamDate, E.StartTime, E.EndTime, C.Name AS CourseName
	FROM Exams.Stud_Exam SE
	JOIN Exams.Exam E ON SE.ExamID = E.ExamID
	JOIN Courses.Course C ON E.CourseID = C.CourseID;
go
--3
create view Person.View_StudentResults as
select 
	SE.StudID,U.Name AS StudentName, C.Name AS CourseName, SE.Total_Mark, SE.[Type]
    FROM Exams.Stud_Exam SE
	JOIN Person.[User] U ON SE.StudID = U.UserID
    JOIN Exams.Exam E ON SE.ExamID = E.ExamID
    JOIN Courses.Course C ON E.CourseID = C.CourseID;
go
--4
CREATE VIEW Courses.View_InstructorCourses AS
SELECT 
    I.InstructorID,
    U.Name AS InstructorName,
    C.Name AS CourseName,
    ITC.TeachYear
FROM Courses.InstructorTeachCourse ITC
JOIN Person.Instructor I ON ITC.InstructorID = I.InstructorID
JOIN Person.[User] U ON I.InstructorID = U.UserID
JOIN Courses.Course C ON ITC.CourseID = C.CourseID;

go
--5
CREATE VIEW Exams.View_ExamQuestions AS
SELECT 
    EQ.ExamID,Q.QuestionNO,Q.Body,Q.Type,Q.CorrectAnswer,Q.BestAnswer
	FROM Exams.Exam_Question EQ
	JOIN Exams.Question Q ON EQ.QuestionNO = Q.QuestionNO;

go
--6
CREATE VIEW Person.View_StudentResultsInCourses AS
SELECT 
    I.InstructorID,U.Name AS InstructorName,S.StdID,SU.Name AS StudentName,C.Name AS CourseName,SE.Total_Mark
FROM Person.Instructor I
JOIN Person.[User] U ON I.InstructorID = U.UserID
JOIN Exams.Exam E ON I.InstructorID = E.instructor_ID
JOIN Exams.Stud_Exam SE ON E.ExamID = SE.ExamID
JOIN Person.Student S ON SE.StudID = S.StdID
JOIN Person.[User] SU ON S.StdID = SU.UserID
JOIN Courses.Course C ON E.CourseID = C.CourseID;

go
--7 View_AllStudents
CREATE VIEW ITI.View_AllStudents
AS
SELECT 
    S.StdID,
    U.Name AS StudentName,
    U.Email,
    U.Phone,
    I.IntakeYear,
    B.Name AS BranchName,
    T.Name AS TrackName
FROM Person.Student S
JOIN Person.[User] U ON S.StdID = U.UserID
join ITI.Class C on s.ClassID = C.ID
join ITI.Branch b on C.BranchID = b.BranchID
join ITI.Track t on C.TrackID = t.TrackID
join ITI.Intake I on C.IntakeID = I.IntakeID

go
--8 View_AllInstructors
CREATE VIEW Courses.View_AllInstructors
AS
SELECT 
    I.InstructorID,
    U.Name AS InstructorName,
    U.Email,
    U.Phone,
    C.Name AS CourseName,
    ITC.TeachYear
FROM Person.Instructor I
JOIN Person.[User] U ON I.InstructorID = U.UserID
LEFT JOIN Courses.InstructorTeachCourse ITC ON I.InstructorID = ITC.InstructorID
LEFT JOIN Courses.Course C ON ITC.CourseID = C.CourseID;

go 
--9 View_AllCourses
CREATE VIEW Courses.View_AllCourses
AS
SELECT 
    C.CourseID,
    C.Name AS CourseName,
    C.Description,
    C.MaxDegree,
    C.MinDegree
FROM Courses.Course C;

go
