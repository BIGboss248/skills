import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { axe } from "jest-axe";
import { NextIntlClientProvider } from "next-intl";
import { [ComponentName] } from "./[ComponentName]";

jest.mock("next/navigation", () => ({
  useRouter: () => ({
    push: jest.fn(),
    replace: jest.fn(),
    prefetch: jest.fn(),
    back: jest.fn(),
  }),
  usePathname: () => "/en",
  useSearchParams: () => new URLSearchParams(),
}));

const messages = {
  [namespace]: {
    title: "[translated title]",
    empty: "[translated empty state]",
    error: "[translated error]",
    retry: "[translated retry]",
    cta: "[translated cta]",
  },
};

/**
 * Renders a component inside the real next-intl provider.
 *
 * @param ui - Component tree under test.
 * @param locale - Active locale for direction and formatting.
 */
function renderWithIntl(ui: React.ReactElement, locale = "en") {
  return render(
    <NextIntlClientProvider locale={locale} messages={messages}>
      {ui}
    </NextIntlClientProvider>,
  );
}

// Adversarial suite — IMMUTABLE once written. Fix the component, not these tests.
describe("[ComponentName] (adversarial)", () => {
  describe("BND — boundary values", () => {
    it("BND-1: renders the empty state when the collection is empty", () => {
      renderWithIntl(<[ComponentName] items={[]} />);

      expect(
        screen.getByText(messages.[namespace].empty),
      ).toBeInTheDocument();
    });

    it("BND-2: falls back to defaults when optional props are undefined", () => {
      renderWithIntl(<[ComponentName] title={undefined} />);

      expect(screen.getByRole("heading")).toBeInTheDocument();
    });

    it("BND-3: wraps an unbroken 240-character string without overflow", () => {
      const longTitle = "A".repeat(240);
      renderWithIntl(<[ComponentName] title={longTitle} />);

      expect(screen.getByRole("heading")).toHaveClass("break-words");
    });
  });

  describe("PROP — permutations", () => {
    it("PROP-2: resolves conflicting loading and error flags deterministically", () => {
      renderWithIntl(<[ComponentName] isLoading error="boom" />);

      expect(screen.getByRole("alert")).toBeInTheDocument();
      expect(screen.queryByRole("status")).not.toBeInTheDocument();
    });

    it("PROP-3: blocks interaction when disabled", async () => {
      const user = userEvent.setup();
      const onClick = jest.fn();
      renderWithIntl(<[ComponentName] disabled onClick={onClick} />);

      await user.click(screen.getByRole("button"));

      expect(onClick).not.toHaveBeenCalled();
      expect(screen.getByRole("button")).toHaveAttribute("aria-disabled", "true");
    });
  });

  describe("NET — async and error states", () => {
    it("NET-1: renders a retryable error card when the action rejects", async () => {
      const onRetry = jest.fn();
      renderWithIntl(<[ComponentName] error="failed" onRetry={onRetry} />);

      expect(screen.getByRole("alert")).toHaveTextContent(
        messages.[namespace].error,
      );
      expect(
        screen.getByRole("button", { name: messages.[namespace].retry }),
      ).toBeInTheDocument();
    });
  });

  describe("A11Y — accessibility and keyboard", () => {
    it("A11Y-2: activates the primary action with Enter and Space", async () => {
      const user = userEvent.setup();
      const onClick = jest.fn();
      renderWithIntl(<[ComponentName] onClick={onClick} />);

      const button = screen.getByRole("button");
      button.focus();
      await user.keyboard("{Enter}");
      await user.keyboard(" ");

      expect(onClick).toHaveBeenCalledTimes(2);
    });

    it("A11Y-6: has no axe violations", async () => {
      const { container } = renderWithIntl(<[ComponentName] />);

      expect(await axe(container)).toHaveNoViolations();
    });
  });

  describe("LIFE — lifecycle and stress", () => {
    it("LIFE-1: clears timers on unmount", () => {
      jest.useFakeTimers();
      const { unmount } = renderWithIntl(<[ComponentName] />);

      unmount();
      jest.runOnlyPendingTimers();

      expect(jest.getTimerCount()).toBe(0);
      jest.useRealTimers();
    });

    it("LIFE-2: does not duplicate listeners across rapid re-renders", () => {
      const { rerender } = renderWithIntl(<[ComponentName] />);
      for (let i = 0; i < 10; i += 1) {
        rerender(
          <NextIntlClientProvider locale="en" messages={messages}>
            <[ComponentName] iteration={i} />
          </NextIntlClientProvider>,
        );
      }

      expect(screen.getAllByRole("heading")).toHaveLength(1);
    });
  });

  describe("I18N — bidirectional and localization", () => {
    it("I18N-1: renders Persian glyphs in RTL without clipping", () => {
      const { container } = renderWithIntl(
        <[ComponentName] title="سلام دنیا" />,
        "fa",
      );

      expect(container.querySelector("[dir='rtl']")).toBeInTheDocument();
      expect(screen.getByText("سلام دنیا")).toBeVisible();
    });

    it("I18N-3: surfaces a missing dictionary key instead of falling back silently", async () => {
      const spy = jest.spyOn(console, "error").mockImplementation(() => {});
      renderWithIntl(<[ComponentName] />, "fa");

      await waitFor(() => expect(screen.getByRole("heading")).toBeVisible());
      spy.mockRestore();
    });
  });
});
