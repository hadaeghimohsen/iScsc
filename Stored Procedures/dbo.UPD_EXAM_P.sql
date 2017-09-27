SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_EXAM_P]
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
   UPDATE Exam
      SET TYPE = @Type
         ,TIME = @Time
         ,CACH_NUMB = @CachNumb
         ,STEP_HEGH = @StepHegh
         ,WEGH = @Wegh
    WHERE RQRO_RQST_RQID = @Rqid
      AND RQRO_RWNO = @RqroRwno
      AND FIGH_FILE_NO = @FileNo
      AND RECT_CODE = @RectCode;
END
GO
