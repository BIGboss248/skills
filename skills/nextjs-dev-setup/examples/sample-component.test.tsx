import "@testing-library/jest-dom";
import { render, screen } from "@testing-library/react";
import Page from "../app/page";

describe("Page Component", () => {
  it("renders heading correctly", () => {
    render(<Page />);
    const heading = screen.getByRole("heading", { level: 1 });
    expect(heading).toBeInTheDocument();
  });

  it("matches snapshot", () => {
    const { container } = render(<Page />);
    expect(container).toMatchSnapshot();
  });
});
