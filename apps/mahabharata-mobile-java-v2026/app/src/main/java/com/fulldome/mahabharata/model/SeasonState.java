package com.fulldome.mahabharata.model;

class SeasonState {
	private boolean purchased = false;
	private String price = null;

	public boolean isPurchased() {
		return purchased;
	}

	public void setPurchased(boolean purchased) {
		this.purchased = purchased;
	}

	public String getPrice() {
		return price;
	}

	public void setPrice(String price) {
		this.price = price;
	}
}
