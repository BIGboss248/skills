'use client'

import * as React from 'react'
import { useActionState } from 'react'
import { useTranslations } from 'next-intl'
import { cn } from '@/lib/utils'

export interface FormState {
  success: boolean
  message?: string
  errors?: Record<string, string[] | undefined>
}

export interface FormComponentProps extends React.HTMLAttributes<HTMLFormElement> {
  actionHandler: (prevState: FormState, formData: FormData) => Promise<FormState>
  initialState?: FormState
}

const defaultInitialState: FormState = {
  success: false,
}

/**
 * Production-ready Accessible Form Component
 *
 * Implements React 19 `useActionState`, BiDi logical properties,
 * semantic tokens, accessible aria-live error messaging, and pending state UI.
 */
export function FormComponent({
  actionHandler,
  initialState = defaultInitialState,
  className,
  ...props
}: FormComponentProps) {
  const t = useTranslations('Form')
  const [state, formAction, isPending] = useActionState(actionHandler, initialState)

  return (
    <form
      action={formAction}
      className={cn('flex flex-col gap-4 text-foreground', className)}
      noValidate
      {...props}
    >
      {/* Global Status Announcement */}
      {state.message && (
        <div
          role="status"
          aria-live="polite"
          className={cn(
            'rounded-md p-3 text-sm font-medium',
            state.success
              ? 'bg-primary/10 text-primary border border-primary/20'
              : 'bg-destructive/10 text-destructive border border-destructive/20'
          )}
        >
          {state.message}
        </div>
      )}

      {/* Field Example */}
      <div className="flex flex-col gap-1.5">
        <label htmlFor="exampleInput" className="text-sm font-medium text-foreground">
          {t('exampleLabel')}
        </label>
        <input
          id="exampleInput"
          name="exampleInput"
          type="text"
          disabled={isPending}
          aria-invalid={Boolean(state.errors?.exampleInput)}
          aria-describedby={state.errors?.exampleInput ? 'exampleInput-error' : undefined}
          className={cn(
            'w-full rounded-md border border-border bg-background px-3 py-2 text-sm text-foreground',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
            'disabled:cursor-not-allowed disabled:opacity-50',
            state.errors?.exampleInput && 'border-destructive focus-visible:ring-destructive'
          )}
        />
        {state.errors?.exampleInput && (
          <p
            id="exampleInput-error"
            aria-live="polite"
            className="text-xs font-medium text-destructive"
          >
            {state.errors.exampleInput[0]}
          </p>
        )}
      </div>

      {/* Actions */}
      <div className="flex items-center justify-end gap-3 pt-2">
        <button
          type="submit"
          disabled={isPending}
          className={cn(
            'inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground',
            'transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
            'disabled:pointer-events-none disabled:opacity-50'
          )}
        >
          {isPending ? t('submitting') : t('submit')}
        </button>
      </div>
    </form>
  )
}
