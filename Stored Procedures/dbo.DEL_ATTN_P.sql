SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [dbo].[DEL_ATTN_P]
	@Club_Code BIGINT,
	@Figh_File_No BIGINT,
	@Attn_Date DATE
AS
BEGIN
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>73</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 73 سطوح امینتی : شما مجوز حذف اطلاعات حضور و غیاب را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   -- پایان دسترسی   
   DELETE Attendance
    WHERE CLUB_CODE = @Club_Code
      AND FIGH_FILE_NO = @Figh_File_No
      AND CAST(ATTN_DATE AS DATE) = CAST(@Attn_Date AS DATE);
END
GO
