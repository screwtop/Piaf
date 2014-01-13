-- Database model for my simple Edita text editor

-- Things to store:
-- Projects (collections of related files)
-- Recent files
-- Maybe a log of all operations for more advanced undo/redo/repeat and general rewriting of history.
-- Script text?
-- Language extensions (e.g. lexical highlighting rules, language-specific Insert snippets).
-- Spelling and grammar data.
-- Unicode character data.

-- Should the model assume a single user (perhaps put the database file in ~/.edita) or multiple users?  It would be easy enough to record <hostname, username> along with each record, so the data could be cloudified and shared universally.

create table File_Log
(
	Hostname varchar,
	Username varchar,
	Filename varchar,
--	PID?
	Date_Performed date,
	Operation varchar,

	constraint File_Log_PK primary key (Hostname, Username, Filename, Date_Performed)
);

create table Project
(
	Username
	Project_Name
	Date_Created
);

-- Files associated with a particular project:
create table Project_Files
(
);


