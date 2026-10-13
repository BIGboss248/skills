import React from "react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { NextIntlClientProvider } from "next-intl";
import { ComponentName } from "./ComponentName";

// Mock next/navigation hooks
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

const mockMessages = {
  ComponentName: {
    title: "Test Component Title",
    description: "Test component description content.",
  },
};

function renderWithIntl(ui: React.ReactElement, locale = "en") {
  return render(
    <NextIntlClientProvider locale={locale} messages={mockMessages}>
      {ui}
    </NextIntlClientProvider>
  );
}

describe("ComponentName Unit Tests", () => {
  it("renders default title and description", async () => {
    // Note: For RSC components, resolve async JSX or render client leaf
    renderWithIntl(<ComponentName locale="en" />);
    
    expect(
      screen.getByRole("heading", { name: "Test Component Title" })
    ).toBeInTheDocument();
    expect(
      screen.getByText("Test component description content.")
    ).toBeInTheDocument();
  });

  it("handles directional layout attributes", () => {
    const { container } = renderWithIntl(
      <div dir="rtl">
        <ComponentName locale="fa" />
      </div>,
      "fa"
    );

    expect(container.firstChild).toHaveAttribute("dir", "rtl");
  });
});
