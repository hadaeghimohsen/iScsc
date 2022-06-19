SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Script for SelectTopNRows command from SSMS  ******/
CREATE VIEW [dbo].[V#App_Message_Box] AS 
SELECT [RWNO]
      ,[RPLY_DATE]
      ,[MESG_TEXT]
      ,[SEND_STAT]
      ,[CHAT_ID]
      ,[FILE_ID]
      ,[FILE_PATH]
      ,[MESG_TYPE]
      ,[LAT]
      ,[LON]
      ,[CONT_CELL_PHON]
      ,[VIST_STAT]
      ,[WHO_SEND]
      ,[SNDR_CHAT_ID]
      ,[HEDR_CODE]
      ,[HEDR_TYPE]
      ,[CONF_STAT]
      ,[CONF_DATE]
      ,[INLN_KEYB_DNRM]
  FROM [iRoboTech].[dbo].[Service_Robot_Replay_Message]
GO
