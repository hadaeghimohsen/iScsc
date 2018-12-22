SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[UPD_MBSM_P]
   @Code BIGINT,
   @Mark_Numb FLOAT,
   @Mark_Desc NVARCHAR(500)
AS 
BEGIN
   UPDATE dbo.Member_Ship_Mark
      SET MARK_NUMB = @Mark_Numb
         ,MARK_DESC = @Mark_Desc
    WHERE CODE = @Code;   
END;
GO
