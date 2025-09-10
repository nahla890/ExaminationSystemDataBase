CREATE DATABASE ExaminationSystemDB
ON PRIMARY (
    NAME = 'ExaminationSystemD_Data',
    FILENAME = 'C:\SQLData\ExamSystem_Data.mdf',
    SIZE = 50MB,
    FILEGROWTH = 10%
),
FILEGROUP ExaminationSystemD_FG1 (
    NAME = 'ExaminationSystemD_FG1_Data',
    FILENAME = 'C:\SQLData\ExamSystem_FG1.ndf',
    SIZE = 50MB,
    FILEGROWTH = 10%
),
FILEGROUP ExaminationSystemD_FG2 (
    NAME = 'ExaminationSystemD_FG2_Data',
    FILENAME = 'C:\SQLData\ExamSystem_FG2.ndf',
    SIZE = 50MB,
    FILEGROWTH = 10%
)
LOG ON (
    NAME = 'ExaminationSystemD_Log',
    FILENAME = 'C:\SQLData\ExamSystem_Log.ldf',
    SIZE = 20MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 10%
);
