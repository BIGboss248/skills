import React from "react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { NextIntlClientProvider } from "next-intl";
import { [ComponentName] } from "./[ComponentName]";

// Mock Next.js routing only — never mock next-intl.
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

// Replace with the real dictionary slice from messages/[locale].json.
const messages = {
  [namespace]: {
    title: "[translated title]",
    description: "[translated description]",
    cta: "[translated cta]",
  },
};

/**
 * Renders a component inside the real next-intl provider.
 *
 * @param ui - Component tree under test.
 * @param locale - Active locale for direction and formatting.
 * @returns Testing Library render result.
 */
function renderWithIntl(ui: React.ReactElement, locale = "en") {
  return render(
    <NextIntlClientProvider locale={locale} messages={messages}>
      {ui}
    </NextIntlClientProvider>,
  );
}

describe("[ComponentName] (baseline)", () => {
  describe("rendering", () => {
    it("renders the translated heading and description", async () => {
      // Synchronous RSC: await the component. Async RSC: move to Playwright.
      const jsx = await [ComponentName]({ locale: "en" });
      renderWithIntl(jsx);

      expect(
        screen.getByRole("heading", { name: messages.[namespace].title }),
      ).toBeInTheDocument();
      expect(
        screen.getByText(messages.[namespace].description),
      ).toBeInTheDocument();
    });

    it("applies the documented defaults when optional props are omitted", () => {
      renderWithIntl(<[ComponentName] />);

      expect(screen.getByRole("region")).toBeInTheDocument();
    });
  });

  describe("interactions", () => {
    it("invokes the callback once per user click", async () => {
      const user = userEvent.setup();
      const onClick = jest.fn();
      renderWithIntl(<[ComponentName] onClick={onClick} />);

      await user.click(
        screen.getByRole("button", { name: messages.[namespace].cta }),
      );

      expect(onClick).toHaveBeenCalledTimes(1);
    });
  });

  describe("states", () => {
    it("renders the skeleton with matching geometry", () => {
      const { container } = render(<[ComponentName]Skeleton />);

      expect(container.firstChild).toHaveClass("animate-pulse");
    });

    it("renders right-to-left when the locale is RTL", () => {
      const { container } = renderWithIntl(
        <[ComponentName] locale="fa" />,
        "fa",
      );

      expect(container.querySelector("[dir='rtl']")).toBeInTheDocument();
    });
  });
});
