SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_PRSN_P](
   @Meet_Mtid BIGINT
  ,@Prsn_Type VARCHAR(3)
  ,@Fgpb_Figh_File_No BIGINT
  ,@Invt_By BIGINT
  ,@Frst_Name NVARCHAR(250)
  ,@Last_Name NVARCHAR(250)
  ,@Fath_Name NVARCHAR(250)
  ,@Natl_Code VARCHAR(10)
  ,@Sex_Type VARCHAR(3)
  ,@Cell_Phon VARCHAR(11)
  ,@Prsn_Desc NVARCHAR(500)
  ,@Prid BIGINT OUT
)
AS
BEGIN
   WAITFOR DELAY '00:00:00:50';
   INSERT INTO [dbo].[Present]
           ([MEET_MTID]
           ,[PRSN_TYPE]
           ,[FGPB_FIGH_FILE_NO]
           ,[INVT_BY]
           ,[FRST_NAME]
           ,[LAST_NAME]
           ,[FATH_NAME]
           ,[NATL_CODE]
           ,[SEX_TYPE]
           ,[CELL_PHON]
           ,[PRSN_DESC]
           ,[PRID])
     VALUES
           (@Meet_Mtid
           ,@Prsn_Type
           ,@Fgpb_Figh_File_No
           ,@Invt_By
           ,@Frst_Name
           ,@Last_Name
           ,@Fath_Name
           ,@Natl_Code
           ,@Sex_Type
           ,@Cell_Phon
           ,@Prsn_Desc
           ,dbo.GNRT_NWID_U());
   
   SELECT @Prid = MAX(PRID)
     FROM Present
    WHERE MEET_MTID = @Meet_Mtid;
END;
GO
