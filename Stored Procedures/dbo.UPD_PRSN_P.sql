SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_PRSN_P](
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
   UPDATE Present
      SET FRST_NAME = @Frst_Name
         ,LAST_NAME = @Last_Name
         ,FATH_NAME = @Fath_Name
         ,NATL_CODE = @Natl_Code
         ,SEX_TYPE  = @Sex_Type
         ,CELL_PHON = @Cell_Phon
         ,PRSN_DESC = @Prsn_Desc
         ,INVT_BY   = @Invt_By
    WHERE PRID = @Prid;
   
END;
GO
