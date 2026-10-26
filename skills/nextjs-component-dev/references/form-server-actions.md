# Forms & Server Actions Reference Guide (`form-server-actions.md`)

This guide outlines architectural standards, patterns, and security constraints for developing form and mutation components using React Server Actions in the Next.js App Router.

---

## 1. Architectural Principles & Routing

When creating or modifying components that accept user input, dispatch mutations, or render `<form>` elements:
1. **RSC & Leaf Client Separation**: The surrounding section or page layout remains a Server Component (`async function`). The interactive form itself or its active input controls must be pushed down to a leaf Client Component (`'use client'`).
2. **Server Action Security Invariant**: Server Actions are public HTTP endpoints. **Never** assume an action is secure simply because its rendering component or route is protected by middleware or layout auth guards. Every Server Action must independently verify authentication and authorization:
   ```tsx
   'use server'
   import { auth } from '@/lib/auth'

   export async function mutateData(prevState: FormState, formData: FormData): Promise<FormState> {
     const session = await auth()
     if (!session?.user) {
       return { success: false, error: 'UNAUTHORIZED' }
     }
     // ...
   }
   ```
3. **Zero Hardcoded Copy**: All labels, validation errors, placeholders, and action feedback messages must be localized via `messages/[locale].json` and consumed via `useTranslations()`.

---

## 2. Decision Matrix: When to Use `useOptimistic` (The Grilling Gate)

Not all forms should be optimistic. Before adding `useOptimistic`, evaluate the mutation type against this matrix:

```mermaid
flowchart TD
    A["Does this component mutate state?"] --> B{"Is it transactional, financial,<br/>or irreversible?"}
    B -->|Yes (Checkout, Auth, Billing, Data Deletion)| C["Do NOT use useOptimistic<br/>Use useActionState + pending indicator"]
    B -->|No| D{"Is immediate visual feedback<br/>expected with trivial rollbacks?"}
    D -->|Yes (Comments, Likes/Reactions, Toggles, Todo lists, Feed posts)| E["USE useOptimistic<br/>Render temporary state immediately"]
    D -->|No (Standard settings form, slow multi-step wizard)| C
```

### Grilling the User on `useOptimistic`
When authoring `implementation_plan.md` or during discovery, probe:
- *"Does the user expect immediate visual continuity (e.g., social feeds, item list append, reaction toggles)?"*
- *"If the server action fails, is a rollback trivial and harmless to UX, or will it cause jarring financial/security confusion?"*
- **Recommendation**:
  - **Recommend `useOptimistic` for**: Append-only list items, likes/upvotes, inline comment additions, item status toggles.
  - **Recommend AGAINST `useOptimistic` for**: Checkout/payment forms, signup/login flows, destructive deletion, complex server-computed validation (e.g., discount coupon calculations).

---

## 3. Core Hook Implementations

### A. React 19 `useActionState` (Standard Form State & Validation)
Standard for forms with server validation errors, return values, and pending status:

```tsx
'use client'

import { useActionState } from 'react'
import { useTranslations } from 'next-intl'
import { createPostAction, type FormState } from './actions'

const initialState: FormState = {
  success: false,
  message: '',
  errors: {},
}

export function PostForm() {
  const t = useTranslations('Posts.form')
  const [state, formAction, isPending] = useActionState(createPostAction, initialState)

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <div>
        <label htmlFor="title" className="block text-sm font-medium text-foreground">
          {t('titleLabel')}
        </label>
        <input
          id="title"
          name="title"
          type="text"
          required
          aria-invalid={Boolean(state.errors?.title)}
          aria-describedby={state.errors?.title ? 'title-error' : undefined}
          className="w-full rounded-md border border-border bg-background px-3 py-2 text-foreground"
        />
        {state.errors?.title && (
          <p id="title-error" aria-live="polite" className="mt-1 text-sm text-destructive">
            {state.errors.title[0]}
          </p>
        )}
      </div>

      <button
        type="submit"
        disabled={isPending}
        className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-primary-foreground disabled:opacity-50"
      >
        {isPending ? t('submitting') : t('submit')}
      </button>
    </form>
  )
}
```

### B. Nested Submit Button with `useFormStatus`
When you want to decouple the submit button or loading spinner into a reusable child component without passing `isPending` props down multiple layers:

```tsx
'use client'

import { useFormStatus } from 'react-dom'
import { useTranslations } from 'next-intl'

export function SubmitButton({ label }: { label: string }) {
  const t = useTranslations('Common')
  const { pending } = useFormStatus()

  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 font-medium text-primary-foreground disabled:opacity-50"
    >
      {pending ? t('loading') : label}
    </button>
  )
}
```

### C. Optimistic Feed/List with `useOptimistic`
When immediate client update is desirable:

```tsx
'use client'

import { useOptimistic, startTransition } from 'react'
import { addCommentAction } from './actions'

type Comment = { id: string; text: string; pending?: boolean }

export function CommentThread({ initialComments }: { initialComments: Comment[] }) {
  const [optimisticComments, addOptimisticComment] = useOptimistic(
    initialComments,
    (current, newCommentText: string) => [
      ...current,
      { id: `temp-${Date.now()}`, text: newCommentText, pending: true },
    ]
  )

  async function handleAction(formData: FormData) {
    const text = formData.get('comment') as string
    if (!text.trim()) return

    startTransition(async () => {
      addOptimisticComment(text)
      await addCommentAction(formData)
    })
  }

  return (
    <div className="space-y-4">
      <ul className="space-y-2">
        {optimisticComments.map((comment) => (
          <li
            key={comment.id}
            className={`rounded border border-border p-3 ${comment.pending ? 'opacity-60 italic' : ''}`}
          >
            {comment.text}
          </li>
        ))}
      </ul>

      <form action={handleAction}>
        <input name="comment" required className="border border-border p-2" />
        <button type="submit">Send</button>
      </form>
    </div>
  )
}
```

---

## 4. Advanced Patterns

### Passing Additional Arguments with `.bind()`
Do not pass confidential data or IDs in unencoded `<input type="hidden">` if progressive enhancement or payload integrity is needed:
```tsx
const updateInvoiceWithId = updateInvoice.bind(null, invoiceId)
return <form action={updateInvoiceWithId}>...</form>
```
The server action signature receives `invoiceId` as the first argument before `formData`:
```tsx
'use server'
export async function updateInvoice(invoiceId: string, formData: FormData) { ... }
```

### Programmatic & Keyboard Submissions (`requestSubmit`)
For `⌘ + Enter` / `Ctrl + Enter` in multiline textareas or auto-saving selects, trigger the nearest form submission programmatically:
```tsx
const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
  if ((e.ctrlKey || e.metaKey) && (e.key === 'Enter' || e.key === 'NumpadEnter')) {
    e.preventDefault()
    e.currentTarget.form?.requestSubmit()
  }
}
```

---

## 5. Testing & Verification Checklist

Form components must satisfy the following tests in their companion `[ComponentName].test.tsx`:
- [ ] Accessible form controls (`getByLabelText`, `getByRole('button')`).
- [ ] Disabled submit button and visible pending state during active submission.
- [ ] Error messages properly linked via `aria-describedby` and announced with `aria-live="polite"`.
- [ ] Schema validation errors rendered correctly without full-page reloads.
- [ ] Successful submission calls Server Action and resets or transitions UI cleanly.
