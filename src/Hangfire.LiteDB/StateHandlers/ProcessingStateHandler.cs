﻿using System;
using Hangfire.Common;
using Hangfire.States;
using Hangfire.Storage;

namespace Hangfire.LiteDB.StateHandlers
{
#pragma warning disable 1591
    public class ProcessingStateHandler : IStateHandler
    {
        public void Apply(ApplyStateContext context, IWriteOnlyTransaction transaction)
        {
            transaction.AddToSet("processing", context.BackgroundJob.Id, JobHelper.ToTimestamp(DateTime.Now));
        }

        public void Unapply(ApplyStateContext context, IWriteOnlyTransaction transaction)
        {
            transaction.RemoveFromSet("processing", context.BackgroundJob.Id);
        }

        public string StateName => ProcessingState.StateName;
    }
#pragma warning restore 1591
}