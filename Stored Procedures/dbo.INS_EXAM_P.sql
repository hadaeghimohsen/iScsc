SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_EXAM_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@Type VARCHAR(3)
  ,@Time SMALLINT
  ,@CachNumb SMALLINT
  ,@StepHegh REAL
  ,@Wegh SMALLINT
AS
BEGIN
   INSERT INTO Exam(RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, TYPE, TIME, CACH_NUMB, STEP_HEGH, WEGH)
   VALUES (@Rqid, @RqroRwno, @FileNo, @RectCode, @Type, @Time, @CachNumb, @StepHegh, @Wegh);
END
GO
